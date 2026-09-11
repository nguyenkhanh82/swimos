#!/usr/bin/env python3
"""
FastAPI service to fetch swimmer times
This service can be deployed on Railway, Render, or similar platforms
and called by the Supabase Edge Function
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import sys
import os

# Add the src directory to the path so we can import SwimScraper
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from SwimScraper import SwimScraperDB as ss

app = FastAPI(title="SwimScraper API")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class SwimmerRequest(BaseModel):
    swimmer_id: int


class SwimmerResponse(BaseModel):
    success: bool
    swimmer_id: int
    events_found: int = 0
    times_found: int = 0
    message: str = ""


@app.get("/")
async def root():
    return {"message": "SwimScraper API", "status": "running"}


@app.post("/fetch-club-teams-from-url")
async def fetch_club_teams_from_url(request: dict):
    """
    Fetch club teams from a specific SwimCloud URL with filters
    """
    url = request.get('url')
    
    if not url:
        raise HTTPException(status_code=400, detail="url is required")
    
    try:
        print(f"Fetching teams from URL: {url}")
        
        from SwimScraper.scrapers import clubs
        teams = clubs.get_club_teams_from_url(url, save_to_db=True)
        
        return {
            "success": True,
            "url": url,
            "teams_found": len(teams),
            "teams": teams[:10] if len(teams) > 10 else teams,  # Return first 10 as sample
            "message": f"Successfully fetched {len(teams)} teams from URL"
        }
        
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/fetch-swimmer-times", response_model=SwimmerResponse)
async def fetch_swimmer_times(request: SwimmerRequest):
    """
    Fetch all events and times for a swimmer
    """
    swimmer_id = request.swimmer_id
    
    try:
        print(f"Fetching times for swimmer ID: {swimmer_id}")
        
        # Get all events for this swimmer
        events = ss.getSwimmerEvents(swimmer_id, save_to_db=True)
        
        if not events:
            return SwimmerResponse(
                success=True,
                swimmer_id=swimmer_id,
                events_found=0,
                times_found=0,
                message=f"No events found for swimmer {swimmer_id}"
            )
        
        # Get times for each event
        total_times = 0
        for event_name in events:
            try:
                times = ss.getSwimmerTimes(swimmer_id, event_name, save_to_db=True)
                if times:
                    total_times += len(times)
            except Exception as e:
                print(f"Error fetching times for {event_name}: {e}")
                continue
        
        return SwimmerResponse(
            success=True,
            swimmer_id=swimmer_id,
            events_found=len(events),
            times_found=total_times,
            message=f"Successfully fetched {len(events)} events and {total_times} times for swimmer {swimmer_id}"
        )
        
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

"""
Database-enabled wrapper for SwimScraper functions
This module extends the original SwimScraper functions to save data to PostgreSQL
"""
from . import SwimScraper as ss
from . import database as db
from .scrapers import teams as teams_scraper
from typing import List, Dict, Any, Optional

# Re-export all original functions
from .SwimScraper import *

def getCollegeTeams(team_names=['NONE'], conference_names=['NONE'], division_names=['NONE'], save_to_db=True):
    """Get college teams and optionally save to database"""
    teams = teams_scraper.getCollegeTeams(team_names, conference_names, division_names)
    if save_to_db and teams:
        db.save_teams(teams)
    return teams

def getRoster(team, gender, team_ID=-1, season_ID=-1, year=-1, pro=False, save_to_db=True):
    """Get roster and optionally save to database"""
    roster = teams_scraper.getRoster(team, gender, team_ID, season_ID, year, pro)
    if save_to_db and roster:
        # Determine team_id and season_id for database
        if team_ID == -1:
            team_ID = ss.getTeamID(team)
        if season_ID == -1 and year != -1:
            season_ID = ss.getSeasonID(year)
        elif season_ID == -1:
            season_ID = 24  # default current season
        
        db.save_roster(roster, team_ID, gender, season_ID, year)
    return roster

def getSwimmerEvents(swimmer_ID, save_to_db=True):
    """Get swimmer events and optionally save to database"""
    events = ss.getSwimmerEvents(swimmer_ID)
    if save_to_db and events:
        db.save_swimmer_events(swimmer_ID, events)
    return events

def getSwimmerTimes(swimmer_ID, event_name, event_ID='', save_to_db=True):
    """Get swimmer times and optionally save to database"""
    times = ss.getSwimmerTimes(swimmer_ID, event_name, event_ID)
    if save_to_db and times:
        db.save_swimmer_times(swimmer_ID, times)
    return times

def getTeamMeetList(team_name='', team_ID=-1, season_ID=-1, year=-1, save_to_db=True):
    """Get team meet list and optionally save to database"""
    meets = teams_scraper.getTeamMeetList(team_name, team_ID, season_ID, year)
    if save_to_db and meets:
        # Determine team_id and year for database
        if team_ID == -1 and team_name:
            team_ID = ss.getTeamID(team_name)
        if year == -1 and season_ID != -1:
            year = ss.getYear(season_ID)
        elif year == -1:
            year = 2021  # default
        
        db.save_meets(meets, team_ID, year)
    return meets

def getCollegeMeetResults(meet_ID, event_name, gender, event_ID=-1, event_href='None', save_to_db=True):
    """Get college meet results and optionally save to database"""
    results = ss.getCollegeMeetResults(meet_ID, event_name, gender, event_ID, event_href)
    if save_to_db and results:
        db.save_meet_results(results, is_pro=False)
    return results

def getProMeetResults(meet_ID, event_name, gender, event_ID=-1, event_href='None', save_to_db=True):
    """Get pro meet results and optionally save to database"""
    results = ss.getProMeetResults(meet_ID, event_name, gender, event_ID, event_href)
    if save_to_db and results:
        db.save_meet_results(results, is_pro=True)
    return results

def getTeamRankingsList(gender, season_ID=-1, year=-1, save_to_db=True):
    """Get team rankings and optionally save to database"""
    rankings = teams_scraper.getTeamRankingsList(gender, season_ID, year)
    if save_to_db and rankings:
        if season_ID == -1 and year != -1:
            season_ID = ss.getSeasonID(year)
        elif season_ID == -1:
            season_ID = 24  # default
        
        db.save_team_rankings(rankings, gender, season_ID, year)
    return rankings

def getHSRecruitRankings(class_year, gender, state='none', state_abbreviation='none', international=False, save_to_db=True):
    """Get HS recruit rankings and optionally save to database"""
    rankings = ss.getHSRecruitRankings(class_year, gender, state, state_abbreviation, international)
    if save_to_db and rankings:
        db.save_hs_recruit_rankings(rankings, class_year, gender)
    return rankings

# SwimTrack Pro - Master App Plan

**Last Updated**: January 11, 2025  
**Status**: In Development

## App Vision

SwimTrack Pro is a comprehensive mobile application for competitive swimmers to track training, manage meets, monitor nutrition, and achieve performance goals. The app supports swimmers at all levels with AI-powered insights and comprehensive data tracking.

## Definition of Done (DoD)

A feature is considered "Done" when:

1. **Functionality**
   - All acceptance criteria are met
   - Feature works on iOS and Android
   - No critical bugs or crashes

2. **Code Quality**
   - Code follows project architecture (feature-first, layered)
   - Uses Riverpod for state management
   - Domain models use Freezed with JSON serialization
   - Proper error handling and loading states
   - No linter errors

3. **Database**
   - Migration files created and tested
   - RLS policies implemented
   - Indexes added for performance
   - Backward compatibility maintained (if applicable)

4. **UI/UX**
   - Matches design system (Google Fonts, color scheme)
   - Responsive and works on different screen sizes
   - Loading and error states implemented
   - Empty states with helpful messaging
   - Accessible (basic accessibility support)

5. **Testing**
   - Manual testing completed
   - Edge cases handled
   - Integration with existing features verified

6. **Documentation**
   - Feature documented in relevant plan/discussion files
   - Database schema updated in docs
   - API changes documented (if applicable)

## Acceptance Criteria Framework

Each feature must have:
- **Given-When-Then** scenarios OR
- **User Story** format with clear success conditions
- **Edge Cases** identified
- **Performance** requirements (if applicable)

---

## Feature Roadmap

### Phase 1: Core Foundation ✅ (Complete)

#### 1.1 Authentication & Onboarding
**Status**: ✅ Complete

**Acceptance Criteria**:
- [x] User can sign up with email/password
- [x] User can sign in with email/password
- [x] User can sign out
- [x] User can delete account
- [x] Protected routes redirect to login when not authenticated
- [x] Authenticated users are redirected from login/welcome screens
- [x] Welcome screen displays app features
- [x] Email confirmation flow works (if enabled)

**Definition of Done**: ✅
- All authentication flows work
- RLS policies protect user data
- Error messages are user-friendly

---

#### 1.2 Home Dashboard
**Status**: ✅ Complete

**Acceptance Criteria**:
- [x] Dashboard displays welcome message with user name
- [x] Training streak card shows current streak
- [x] Weekly training volume chart displays (mock data)
- [x] Current goals list shows progress
- [x] Recent activity feed displays
- [x] Quick actions FAB opens menu with options
- [x] Upcoming meets preview shows next meet
- [x] Navigation to other tabs works

**Definition of Done**: ✅
- Dashboard loads without errors
- All sections render correctly
- Navigation works

---

#### 1.3 Meets Management
**Status**: ✅ Complete (Basic)

**Acceptance Criteria**:
- [x] User can create a new meet (name, date, location, pool type)
- [x] User can view list of all meets
- [x] User can view meet details
- [x] User can add meet entries (event, time, place, PB flag)
- [x] Meet entries display in "My Events" tab
- [x] Heat sheet tab shows placeholder
- [x] Meets are sorted by date

**Definition of Done**: ✅
- CRUD operations work
- Data persists in database
- UI is functional

**Future Enhancements**:
- Edit/delete meets
- Edit/delete entries
- Heat sheet integration
- Standards analysis

---

### Phase 2: Training & Teams (In Planning)

#### 2.1 Training Tab with Teams Management
**Status**: 📋 Planned

**Acceptance Criteria**:

**Team Management**:
- [ ] User can create a team (name, location, type, level)
- [ ] User can add multiple coaches to a team
- [ ] User can import team from SportEngines (Phase 4)
- [ ] User can view all their teams (active and past)
- [ ] User can join/leave teams
- [ ] User can select multiple active teams
- [ ] Team types: Regular, Camp, Private Coach, Self

**Practice Tracking**:
- [ ] User can log practice session for selected team(s)
- [ ] Practice includes: date, team(s), sets, splits
- [ ] User can view training history
- [ ] Training history filters by: team, distance, stroke, date range
- [ ] User can create custom events to track
- [ ] Practices show team badges

**Definition of Done**:
- All database tables created with RLS
- Team selection UI works
- Practice logging associates with teams
- Filtering works correctly
- Backward compatible with existing training_sets

**See**: [Training Tab Plan](./training-tab-teams-management.md)

---

### Phase 3: Nutrition (Planned)

#### 3.1 Nutrition Tracking
**Status**: 📋 Planned

**Acceptance Criteria**:
- [ ] User can log meals (name, calories, macros)
- [ ] User can set daily nutrition goals
- [ ] User can view daily nutrition summary
- [ ] User can view weekly nutrition trends
- [ ] Charts show goal progress
- [ ] User can edit/delete meal entries

**Definition of Done**:
- Meal logging works
- Goals persist
- Charts render correctly
- Calculations are accurate

---

#### 3.2 AI Meal Planning
**Status**: ✅ Backend Complete, ⏳ Frontend Pending

**Acceptance Criteria**:
- [x] Edge function generates meal plan (backend)
- [ ] User can trigger meal plan generation from UI
- [ ] Generated meal plan displays in app
- [ ] User can save meal plan to nutrition log
- [ ] Error handling for API failures
- [ ] Loading states during generation

**Definition of Done**:
- UI integration complete
- Error handling works
- User can use generated plans

---

### Phase 4: Advanced Features (Future)

#### 4.1 Standards Analysis
**Status**: 📋 Planned

**Acceptance Criteria**:
- [ ] User can view achieved time standards (A, AA, AAA, etc.)
- [ ] System calculates next cut time
- [ ] Progress bars show progress toward next standard
- [ ] Standards are based on: gender, age, event, course
- [ ] Standards data is seeded from USA Swimming

**Definition of Done**:
- Standards service implemented
- UI displays analysis correctly
- Calculations are accurate

---

#### 4.2 Race Plan Generation
**Status**: ✅ Backend Complete, ⏳ Frontend Pending

**Acceptance Criteria**:
- [x] Edge function generates race plan (backend)
- [ ] User can generate race plan from meet entry
- [ ] Race plan displays with splits and strategy
- [ ] User can save/share race plan
- [ ] Error handling for API failures

**Definition of Done**:
- UI integration complete
- Race plans are useful and accurate

---

#### 4.3 SportEngines Integration
**Status**: 📋 Research Phase

**Acceptance Criteria**:
- [ ] User can authenticate with SportEngines
- [ ] User can import team data
- [ ] Imported teams sync correctly
- [ ] Error handling for import failures

**Definition of Done**:
- OAuth flow works
- Data mapping is correct
- Import is reliable


---

### Phase 5: Profile & Settings (Partial)

#### 5.1 User Profile
**Status**: ⏳ Basic Implementation

**Acceptance Criteria**:
- [ ] User can view profile information
- [ ] User can edit profile (name, team, stroke, etc.)
- [ ] User can upload avatar
- [ ] User can change password
- [ ] User can delete account

**Definition of Done**:
- Profile editing works
- Avatar upload works
- Account deletion works

---

## Feature Status Legend

- ✅ **Complete**: Feature is fully implemented and meets DoD
- ⏳ **In Progress**: Feature is partially implemented
- 📋 **Planned**: Feature is planned but not started
- 🔄 **In Review**: Feature is complete but needs review/testing

---

## Success Metrics

### User Engagement
- Daily active users
- Session duration
- Features used per session

### Data Quality
- Number of practices logged per user
- Number of meets tracked
- Nutrition entries per week

### Performance
- App load time < 2 seconds
- Screen transitions < 100ms
- API response times < 500ms

### Quality
- Crash rate < 0.1%
- Error rate < 1%
- User satisfaction (future: surveys)

---

## Technical Debt & Improvements

### High Priority
1. **Training Tab**: Currently placeholder, needs full implementation
2. **Nutrition Tab**: Currently placeholder, needs full implementation
3. **Profile Screen**: Basic implementation, needs full features
4. **Standards Analysis**: Mentioned in docs but not implemented

### Medium Priority
1. **Error Handling**: Standardize error messages
2. **Loading States**: Consistent loading indicators
3. **Offline Support**: Basic offline capability
4. **Testing**: Add unit and widget tests

### Low Priority
1. **Performance Optimization**: Code splitting, lazy loading
2. **Accessibility**: Full accessibility support
3. **Internationalization**: Multi-language support
4. **Analytics**: User behavior tracking

---

## Next Steps

1. **Immediate**: Complete Training Tab implementation (Phase 2.1)
2. **Short-term**: Complete Nutrition Tab (Phase 3.1)
3. **Medium-term**: Standards Analysis (Phase 4.1)
4. **Long-term**: SportEngines Integration (Phase 4.3)

---

## Notes

- All features must follow the established architecture (feature-first, layered)
- Database migrations must be backward compatible when possible
- UI must match the design system (Google Fonts, color scheme)
- All user data must be protected with RLS policies
- Features should be built incrementally and tested thoroughly

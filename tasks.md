# Implementation Tasks - Real-Time Quiz Server

**Project**: Real-Time Vocabulary Quiz System  
**Component**: WebSocket Quiz Server (Go)  
**Last Updated**: November 16, 2025

---

## Task Status Legend
- ⏳ **Not Started**: Task hasn't been started yet
- 🏗️ **In Progress**: Currently being worked on
- ✅ **Completed**: Task finished and validated
- ⏸️ **Blocked**: Waiting on dependencies or external factors
- ⚠️ **At Risk**: Potential issues identified

---

## Phase 1: Foundation (MVP)

**Goal**: Basic real-time quiz server with core functionality  
**Duration**: 2-3 days  
**Status**: ⏳ Not Started

### Task 1.1: Project Setup & Structure
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 2 hours  
**Dependencies**: None

**Description**:
Set up Go project with proper directory structure following DDD principles and Go best practices.

**Acceptance Criteria**:
- [ ] Initialize Go module (`go mod init`)
- [ ] Create directory structure (domain/, application/, infrastructure/, presentation/)
- [ ] Set up `.gitignore` for Go projects
- [ ] Create `README.md` with setup instructions
- [ ] Initialize `docker-compose.yml` for dependencies (Redis, PostgreSQL)
- [ ] Set up `Makefile` with common commands (build, test, run, docker-up)

**Implementation Steps**:
1. Run `go mod init github.com/[username]/quiz-server`
2. Create directory structure:
   ```
   /cmd/server/main.go           # Application entry point
   /internal/domain/              # Domain models
   /internal/application/         # Use cases, services
   /internal/infrastructure/      # External dependencies
   /internal/presentation/        # WebSocket handlers
   /pkg/                          # Public libraries
   /test/                         # Integration tests
   /scripts/                      # Utility scripts
   /configs/                      # Configuration files
   ```
3. Create `docker-compose.yml` with Redis and PostgreSQL services
4. Create `Makefile` with targets: `build`, `test`, `run`, `docker-up`, `docker-down`, `lint`

**AI Collaboration**:
- Use Copilot for generating boilerplate Makefile
- Use Claude for reviewing directory structure against DDD principles

**Verification**:
- Project structure follows Go conventions
- `go build` succeeds
- `docker-compose up` starts dependencies
- All directories have proper `.gitkeep` or initial files

---

### Task 1.2: Domain Models Definition
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 3 hours  
**Dependencies**: Task 1.1

**Description**:
Define core domain entities, value objects, and aggregates in pure Go (no infrastructure dependencies).

**Acceptance Criteria**:
- [ ] Define `QuizSession` aggregate
- [ ] Define `Participant` entity
- [ ] Define `AnswerSubmission` entity
- [ ] Define `Score` value object
- [ ] Define `LeaderboardEntry` value object
- [ ] Define domain events (UserJoined, ScoreUpdated, etc.)
- [ ] Add validation logic to domain models
- [ ] Write unit tests for domain logic (>90% coverage)

**Implementation Steps**:
1. Create `/internal/domain/quiz_session.go`:
   ```go
   type QuizSession struct {
       ID            string
       QuizID        string
       Status        SessionStatus
       Participants  map[string]*Participant
       StartTime     time.Time
       EndTime       *time.Time
       MaxParticipants int
   }
   ```
2. Create `/internal/domain/participant.go`
3. Create `/internal/domain/answer.go`
4. Create `/internal/domain/events.go`
5. Create `/internal/domain/value_objects.go`
6. Implement validation methods (e.g., `Validate()`, `CanJoin()`)
7. Write unit tests in `*_test.go` files

**AI Collaboration**:
- Use Copilot to generate struct definitions from design doc
- Use Claude to review domain model relationships and validation logic

**Verification**:
- All domain models compile without imports from infrastructure
- Unit tests pass (`go test ./internal/domain/...`)
- Code passes linting (`golangci-lint run`)

---

### Task 1.3: WebSocket Server Setup
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 4 hours  
**Dependencies**: Task 1.1

**Description**:
Implement basic WebSocket server using gorilla/websocket with connection handling.

**Acceptance Criteria**:
- [ ] Install gorilla/websocket library
- [ ] Create WebSocket upgrader with proper configuration
- [ ] Implement `/ws` endpoint with connection handling
- [ ] Handle WebSocket connection lifecycle (connect, disconnect)
- [ ] Implement basic message reading/writing
- [ ] Add connection timeout handling
- [ ] Implement graceful shutdown
- [ ] Create simple test client for validation

**Implementation Steps**:
1. Install dependencies: `go get github.com/gorilla/websocket`
2. Create `/internal/presentation/websocket/handler.go`:
   ```go
   type Handler struct {
       upgrader websocket.Upgrader
       connections map[string]*websocket.Conn
       mu sync.RWMutex
   }
   
   func (h *Handler) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
       conn, err := h.upgrader.Upgrade(w, r, nil)
       // Handle connection...
   }
   ```
3. Create connection manager in `/internal/presentation/websocket/manager.go`
4. Implement read/write goroutines per connection
5. Add heartbeat/ping-pong mechanism
6. Create `/test/client/simple_client.go` for testing
7. Implement graceful shutdown in `main.go`

**AI Collaboration**:
- Use Copilot for gorilla/websocket boilerplate
- Use Claude for concurrency patterns and race condition prevention

**Verification**:
- Test client can connect to server
- Multiple concurrent connections work
- Graceful shutdown closes all connections
- No goroutine leaks (use `go test -race`)

---

### Task 1.4: Message Protocol Implementation
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 3 hours  
**Dependencies**: Task 1.2, Task 1.3

**Description**:
Implement JSON message protocol for client-server communication.

**Acceptance Criteria**:
- [ ] Define message types (JOIN_SESSION, SUBMIT_ANSWER, etc.)
- [ ] Create message structs with JSON tags
- [ ] Implement message parser/validator
- [ ] Implement message serializer
- [ ] Add error message handling
- [ ] Create message routing logic
- [ ] Write unit tests for message parsing

**Implementation Steps**:
1. Create `/internal/presentation/websocket/messages.go`:
   ```go
   type MessageType string
   
   const (
       JoinSession     MessageType = "JOIN_SESSION"
       SubmitAnswer    MessageType = "SUBMIT_ANSWER"
       LeaveSession    MessageType = "LEAVE_SESSION"
       ScoreUpdated    MessageType = "SCORE_UPDATED"
       // ... more types
   )
   
   type Message struct {
       Type      MessageType `json:"type"`
       Payload   interface{} `json:"payload"`
       Timestamp time.Time   `json:"timestamp"`
       MessageID string      `json:"message_id"`
   }
   ```
2. Create specific payload structs (JoinSessionPayload, etc.)
3. Implement `ParseMessage(data []byte) (*Message, error)`
4. Implement `SerializeMessage(msg *Message) ([]byte, error)`
5. Create message validator
6. Implement message router in handler

**AI Collaboration**:
- Use Copilot for JSON struct generation
- Use Claude for validation logic review

**Verification**:
- All message types parse correctly
- Invalid messages return appropriate errors
- Serialization roundtrip preserves data
- Unit tests cover all message types

---

### Task 1.5: In-Memory Session Management
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 4 hours  
**Dependencies**: Task 1.2, Task 1.4

**Description**:
Implement in-memory session management for MVP (before adding Redis/PostgreSQL).

**Acceptance Criteria**:
- [ ] Create session repository interface
- [ ] Implement in-memory repository
- [ ] Add thread-safe session operations (Create, Get, Update, Delete)
- [ ] Implement participant management (Join, Leave)
- [ ] Add session lifecycle management (Waiting → Active → Completed)
- [ ] Write unit tests for repository

**Implementation Steps**:
1. Define repository interface in `/internal/domain/repositories.go`:
   ```go
   type SessionRepository interface {
       Create(session *QuizSession) error
       Get(sessionID string) (*QuizSession, error)
       Update(session *QuizSession) error
       Delete(sessionID string) error
       AddParticipant(sessionID string, participant *Participant) error
   }
   ```
2. Implement in `/internal/infrastructure/repository/memory/session_repository.go`
3. Use `sync.RWMutex` for thread safety
4. Implement session state transitions
5. Add TTL cleanup goroutine (optional for MVP)

**AI Collaboration**:
- Use Copilot for interface and struct definitions
- Use Claude for concurrency safety review

**Verification**:
- Concurrent operations don't cause race conditions (`go test -race`)
- All CRUD operations work correctly
- Session state transitions follow rules
- Unit tests achieve >80% coverage

---

### Task 1.6: Quiz Content Mock
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 2 hours  
**Dependencies**: Task 1.2

**Description**:
Create mock quiz content repository with predefined questions and answers.

**Acceptance Criteria**:
- [ ] Define Quiz and Question domain models
- [ ] Create static JSON file with sample quiz data
- [ ] Implement quiz repository interface
- [ ] Implement in-memory quiz loader
- [ ] Add answer validation logic
- [ ] Include at least 20 vocabulary questions

**Implementation Steps**:
1. Create `/internal/domain/quiz.go`:
   ```go
   type Quiz struct {
       ID        string
       Title     string
       Questions []Question
   }
   
   type Question struct {
       ID            string
       Text          string
       Options       []string
       CorrectAnswer string
       Points        int
   }
   ```
2. Create `/data/quizzes/vocab-101.json` with sample questions
3. Create `/internal/infrastructure/repository/memory/quiz_repository.go`
4. Implement JSON file loader
5. Add `ValidateAnswer(questionID, answer string) (bool, error)` method

**AI Collaboration**:
- Use ChatGPT to generate 20 vocabulary quiz questions
- Use Copilot for JSON parsing boilerplate

**Verification**:
- Quiz data loads successfully
- Answer validation works correctly
- All questions have valid structure

---

### Task 1.7: Scoring Engine Implementation
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 4 hours  
**Dependencies**: Task 1.5, Task 1.6

**Description**:
Implement scoring engine that validates answers and calculates points.

**Acceptance Criteria**:
- [ ] Create scoring service interface
- [ ] Implement answer validation
- [ ] Implement score calculation (base points + time bonus)
- [ ] Add atomic score update logic
- [ ] Prevent duplicate answer submissions
- [ ] Write unit tests for scoring logic
- [ ] Document scoring algorithm

**Implementation Steps**:
1. Create `/internal/application/scoring_service.go`:
   ```go
   type ScoringService struct {
       quizRepo    domain.QuizRepository
       sessionRepo domain.SessionRepository
   }
   
   func (s *ScoringService) SubmitAnswer(ctx context.Context, submission *AnswerSubmission) (*ScoreResult, error) {
       // Validate, calculate, update
   }
   ```
2. Implement scoring algorithm:
   - Base points: 10 per correct answer
   - Time bonus: max(0, 5 - floor(timeTaken/2seconds))
   - Incorrect: 0 points
3. Check for duplicate submissions
4. Update participant score atomically
5. Return score result

**AI Collaboration**:
- Use Claude to review scoring algorithm fairness
- Use Copilot for calculation logic

**Verification**:
- Correct answers award proper points
- Time bonus calculates correctly
- Incorrect answers give 0 points
- Duplicate submissions are rejected
- Unit tests cover edge cases

---

### Task 1.8: Basic Leaderboard Service
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 3 hours  
**Dependencies**: Task 1.5, Task 1.7

**Description**:
Implement in-memory leaderboard with ranking calculation.

**Acceptance Criteria**:
- [ ] Create leaderboard service
- [ ] Implement ranking calculation (sort by score, then by join time)
- [ ] Add GetLeaderboard method with pagination
- [ ] Update leaderboard on score changes
- [ ] Handle ties correctly
- [ ] Write unit tests

**Implementation Steps**:
1. Create `/internal/application/leaderboard_service.go`:
   ```go
   type LeaderboardService struct {
       sessionRepo domain.SessionRepository
   }
   
   func (ls *LeaderboardService) GetLeaderboard(sessionID string, limit, offset int) ([]LeaderboardEntry, error) {
       // Fetch participants, sort, rank
   }
   ```
2. Implement sorting logic (score DESC, joinedAt ASC)
3. Calculate ranks handling ties
4. Implement pagination (limit/offset)
5. Create UpdateRanking method

**AI Collaboration**:
- Use Copilot for sorting/ranking algorithms
- Use Claude for tie-handling logic review

**Verification**:
- Rankings are correct for various score distributions
- Ties are handled consistently
- Pagination works correctly
- Performance is acceptable for 1000+ participants

---

### Task 1.9: WebSocket Message Handlers
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 5 hours  
**Dependencies**: Task 1.4, Task 1.5, Task 1.7, Task 1.8

**Description**:
Implement handlers for all WebSocket message types (JOIN, SUBMIT_ANSWER, etc.).

**Acceptance Criteria**:
- [ ] Implement JOIN_SESSION handler
- [ ] Implement SUBMIT_ANSWER handler
- [ ] Implement LEAVE_SESSION handler
- [ ] Implement PING/PONG handler
- [ ] Add error handling for all handlers
- [ ] Implement broadcast logic
- [ ] Write integration tests

**Implementation Steps**:
1. Create `/internal/presentation/websocket/handlers/` directory
2. Implement `join_handler.go`:
   - Validate session ID
   - Add participant to session
   - Send SESSION_JOINED response
   - Broadcast USER_JOINED to others
3. Implement `answer_handler.go`:
   - Call scoring service
   - Send SCORE_UPDATED to user
   - Broadcast leaderboard update
4. Implement `leave_handler.go`
5. Wire handlers to message router
6. Add error responses for failures

**AI Collaboration**:
- Use Copilot for handler boilerplate
- Use Claude for error handling patterns

**Verification**:
- Each handler processes messages correctly
- Error cases return proper error messages
- Broadcasts reach all session participants
- Integration tests pass

---

### Task 1.10: Simple Test Client
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 3 hours  
**Dependencies**: Task 1.9

**Description**:
Create simple command-line test client to validate server functionality.

**Acceptance Criteria**:
- [ ] Client can connect to WebSocket server
- [ ] Client can send JOIN_SESSION message
- [ ] Client can submit answers
- [ ] Client displays received messages (score updates, leaderboard)
- [ ] Client handles disconnections gracefully
- [ ] Support multiple client instances for testing

**Implementation Steps**:
1. Create `/cmd/client/main.go`
2. Implement WebSocket connection logic
3. Add CLI for user input (session ID, answers)
4. Display received messages in formatted output
5. Add auto-reconnect logic
6. Create script to run multiple clients

**AI Collaboration**:
- Use Copilot for WebSocket client boilerplate
- Use Claude for CLI design

**Verification**:
- Client connects successfully
- Messages are sent and received
- Multiple clients can interact simultaneously

---

### Task 1.11: MVP Integration Testing
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 4 hours  
**Dependencies**: All Phase 1 tasks

**Description**:
End-to-end testing of MVP functionality with multiple simulated users.

**Acceptance Criteria**:
- [ ] Create integration test suite
- [ ] Test scenario: 10 users join session
- [ ] Test scenario: Users submit answers concurrently
- [ ] Test scenario: Leaderboard updates correctly
- [ ] Test scenario: User disconnects and reconnects
- [ ] Test error scenarios (invalid session, duplicate answers)
- [ ] Document test results

**Implementation Steps**:
1. Create `/test/integration/` directory
2. Write test scenarios using Go testing package
3. Create helper functions for spawning test clients
4. Run concurrent operations and verify results
5. Test edge cases and error conditions
6. Generate test report

**AI Collaboration**:
- Use Claude for test scenario suggestions
- Use Copilot for test code generation

**Verification**:
- All integration tests pass
- No race conditions detected
- Error handling works as expected

---

## Phase 2: Persistence & Scaling

**Goal**: Add Redis/PostgreSQL, support multiple instances  
**Duration**: 2-3 days  
**Status**: ⏳ Not Started

### Task 2.1: Redis Integration
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 4 hours  
**Dependencies**: Phase 1 complete

**Description**:
Integrate Redis for session state and caching.

**Acceptance Criteria**:
- [ ] Install go-redis library
- [ ] Create Redis client wrapper
- [ ] Implement session repository using Redis
- [ ] Implement leaderboard using Redis sorted sets
- [ ] Add connection pooling configuration
- [ ] Implement health checks for Redis
- [ ] Write integration tests with testcontainers

**Implementation Steps**:
1. Install: `go get github.com/go-redis/redis/v8`
2. Create `/internal/infrastructure/redis/client.go`
3. Implement `/internal/infrastructure/repository/redis/session_repository.go`
4. Implement `/internal/infrastructure/repository/redis/leaderboard_repository.go`
5. Use Redis data structures:
   - Hash for session: `session:{sessionID}`
   - Sorted Set for leaderboard: `leaderboard:{sessionID}`
6. Add unit tests and integration tests

**AI Collaboration**:
- Use Copilot for Redis client setup
- Use Claude for data structure design review

**Verification**:
- All operations work with Redis
- Connection pooling configured correctly
- Integration tests pass with testcontainers
- Performance comparable to in-memory version

---

### Task 2.2: PostgreSQL Integration
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 5 hours  
**Dependencies**: Task 2.1

**Description**:
Integrate PostgreSQL for persistent storage.

**Acceptance Criteria**:
- [ ] Create database schema (migrations)
- [ ] Install database driver (lib/pq or pgx)
- [ ] Implement repositories for PostgreSQL
- [ ] Add connection pooling
- [ ] Implement database health checks
- [ ] Write integration tests

**Implementation Steps**:
1. Create `/migrations/001_initial_schema.up.sql`
2. Install: `go get github.com/lib/pq` and migration tool
3. Create `/internal/infrastructure/postgres/client.go`
4. Implement repositories in `/internal/infrastructure/repository/postgres/`
5. Configure connection pool (max connections: 25)
6. Add prepared statements for common queries

**AI Collaboration**:
- Use Copilot for SQL schema generation
- Use Claude for query optimization review

**Verification**:
- Schema migrations run successfully
- CRUD operations work correctly
- Indexes improve query performance
- Integration tests pass

---

### Task 2.3: Pub/Sub Implementation
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 4 hours  
**Dependencies**: Task 2.1

**Description**:
Implement Redis Pub/Sub for cross-instance messaging.

**Acceptance Criteria**:
- [ ] Create event bus abstraction
- [ ] Implement Redis Pub/Sub client
- [ ] Add event publishing logic
- [ ] Add event subscription logic
- [ ] Implement event handlers
- [ ] Test with multiple server instances

**Implementation Steps**:
1. Create `/internal/infrastructure/pubsub/event_bus.go`:
   ```go
   type EventBus interface {
       Publish(event DomainEvent) error
       Subscribe(eventType EventType, handler EventHandler) error
   }
   ```
2. Implement Redis Pub/Sub client
3. Create channels per event type: `events:{sessionID}:{eventType}`
4. Implement message routing to local connections
5. Add error handling and retries

**AI Collaboration**:
- Use Copilot for Pub/Sub boilerplate
- Use Claude for message routing design

**Verification**:
- Events published from one instance reach others
- Message delivery is reliable
- No duplicate message handling
- Performance meets targets (<50ms propagation)

---

### Task 2.4: Atomic Score Updates
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 3 hours  
**Dependencies**: Task 2.1, Task 2.2

**Description**:
Ensure score updates are atomic using Redis and database transactions.

**Acceptance Criteria**:
- [ ] Use Redis INCRBY for atomic score increments
- [ ] Implement optimistic locking for database writes
- [ ] Add conflict resolution logic
- [ ] Handle race conditions correctly
- [ ] Write concurrency tests

**Implementation Steps**:
1. Modify scoring service to use Redis INCRBY
2. Implement database write-behind pattern
3. Add version field for optimistic locking
4. Handle concurrent update conflicts
5. Write test with 100 concurrent score updates

**AI Collaboration**:
- Use Claude for concurrency patterns review
- Use Copilot for transaction code

**Verification**:
- No score updates are lost
- Final scores are correct under concurrent load
- Race detector shows no issues

---

### Task 2.5: Connection Manager Refactoring
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 4 hours  
**Dependencies**: Task 2.3

**Description**:
Refactor connection manager to support multiple server instances.

**Acceptance Criteria**:
- [ ] Track connections per server instance
- [ ] Implement cross-instance broadcast via Pub/Sub
- [ ] Add connection state synchronization
- [ ] Handle instance failures gracefully
- [ ] Test failover scenarios

**Implementation Steps**:
1. Add instance ID to connection manager
2. Store connection → instance mapping in Redis
3. Subscribe to Pub/Sub for broadcast messages
4. Route messages to local connections only
5. Implement health check and cleanup

**AI Collaboration**:
- Use Claude for distributed system design review
- Use Copilot for routing logic

**Verification**:
- Messages reach correct instances
- Failover works when instance crashes
- No orphaned connections

---

### Task 2.6: Multi-Instance Testing
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 3 hours  
**Dependencies**: Task 2.5

**Description**:
Test server with multiple instances and load balancer.

**Acceptance Criteria**:
- [ ] Set up Docker Compose with 3 server instances
- [ ] Configure nginx as load balancer with sticky sessions
- [ ] Test users connecting to different instances
- [ ] Verify cross-instance messaging works
- [ ] Test instance failure and recovery

**Implementation Steps**:
1. Update `docker-compose.yml` with 3 server replicas
2. Add nginx configuration for load balancing
3. Create test script simulating distributed users
4. Test failover by stopping/starting instances
5. Measure performance under distributed load

**AI Collaboration**:
- Use Copilot for nginx configuration
- Use Claude for load testing strategy

**Verification**:
- Users on different instances can interact
- Sticky sessions work correctly
- Failover is transparent to users

---

## Phase 3: Observability & Reliability

**Goal**: Production-ready monitoring and error handling  
**Duration**: 1-2 days  
**Status**: ⏳ Not Started

### Task 3.1: Prometheus Metrics
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 4 hours  
**Dependencies**: Phase 2 complete

**Description**:
Integrate Prometheus for metrics collection.

**Acceptance Criteria**:
- [ ] Install prometheus/client_go
- [ ] Create metrics registry
- [ ] Add system metrics (connections, sessions, errors)
- [ ] Add business metrics (answers, scores)
- [ ] Add performance metrics (latency histograms)
- [ ] Expose /metrics endpoint
- [ ] Create Grafana dashboard

**Implementation Steps**:
1. Install: `go get github.com/prometheus/client_go`
2. Create `/internal/infrastructure/metrics/collector.go`
3. Define metrics:
   ```go
   var (
       activeConnections = prometheus.NewGauge(...)
       messageLatency = prometheus.NewHistogram(...)
       errorsTotal = prometheus.NewCounter(...)
   )
   ```
4. Instrument code with metrics collection
5. Create `/configs/grafana_dashboard.json`

**AI Collaboration**:
- Use Copilot for metric definitions
- Use Claude for dashboard design

**Verification**:
- Metrics are collected correctly
- Grafana dashboard displays data
- Metrics provide useful insights

---

### Task 3.2: Structured Logging
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 3 hours  
**Dependencies**: None (can be done anytime)

**Description**:
Implement structured logging with Uber Zap.

**Acceptance Criteria**:
- [ ] Install uber-go/zap
- [ ] Create logger wrapper
- [ ] Add contextual logging (user_id, session_id, trace_id)
- [ ] Configure log levels (DEBUG, INFO, WARN, ERROR)
- [ ] Add log rotation
- [ ] Write logs in JSON format

**Implementation Steps**:
1. Install: `go get go.uber.org/zap`
2. Create `/internal/infrastructure/logger/logger.go`
3. Configure zap with production config
4. Add context middleware for trace IDs
5. Replace all `fmt.Println` with structured logs
6. Configure log output (stdout for containers)

**AI Collaboration**:
- Use Copilot for zap configuration
- Use Claude for logging best practices

**Verification**:
- Logs are structured JSON
- Log levels work correctly
- Contextual fields are included
- Performance impact is minimal

---

### Task 3.3: Health Checks
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 2 hours  
**Dependencies**: Task 2.1, Task 2.2

**Description**:
Implement health check endpoints for Kubernetes/Docker.

**Acceptance Criteria**:
- [ ] Create /health/live endpoint (liveness)
- [ ] Create /health/ready endpoint (readiness)
- [ ] Check Redis connection
- [ ] Check PostgreSQL connection
- [ ] Check memory usage
- [ ] Return appropriate HTTP status codes

**Implementation Steps**:
1. Create `/internal/presentation/http/health_handler.go`
2. Implement liveness check (always returns 200 if server running)
3. Implement readiness check:
   - Ping Redis
   - Ping PostgreSQL
   - Check memory < 90%
4. Return 200 if healthy, 503 if not ready

**AI Collaboration**:
- Use Copilot for health check logic
- Use Claude for readiness criteria review

**Verification**:
- Health checks return correct status
- Failed dependencies cause readiness to fail
- Liveness remains healthy even if dependencies fail

---

### Task 3.4: Error Handling & Recovery
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 5 hours  
**Dependencies**: Task 3.2

**Description**:
Implement comprehensive error handling and recovery mechanisms.

**Acceptance Criteria**:
- [ ] Create error types/codes
- [ ] Implement circuit breaker for external services
- [ ] Add retry logic with exponential backoff
- [ ] Implement panic recovery middleware
- [ ] Add timeout handling
- [ ] Document error handling strategy

**Implementation Steps**:
1. Create `/internal/domain/errors.go` with error types
2. Implement circuit breaker for Redis/PostgreSQL
3. Add retry decorator:
   ```go
   func WithRetry(fn func() error, maxRetries int) error {
       // Exponential backoff retry
   }
   ```
4. Add panic recovery in WebSocket handler
5. Set timeouts for all operations
6. Update error responses to clients

**AI Collaboration**:
- Use Claude for circuit breaker pattern
- Use Copilot for retry logic

**Verification**:
- Circuit breaker opens on failures
- Retries work with exponential backoff
- Panics are recovered gracefully
- Error messages are informative

---

### Task 3.5: Graceful Shutdown
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 3 hours  
**Dependencies**: Task 3.4

**Description**:
Implement graceful shutdown to cleanly close connections and save state.

**Acceptance Criteria**:
- [ ] Handle SIGTERM and SIGINT signals
- [ ] Stop accepting new connections
- [ ] Wait for in-flight requests to complete (with timeout)
- [ ] Close WebSocket connections gracefully
- [ ] Flush logs and metrics
- [ ] Close database connections

**Implementation Steps**:
1. Create signal handler in `main.go`
2. Implement shutdown sequence:
   - Stop HTTP server
   - Notify clients of shutdown
   - Wait for connections to close (30s timeout)
   - Close database connections
   - Flush logs
3. Add shutdown hooks for cleanup
4. Test with `kill -SIGTERM <pid>`

**AI Collaboration**:
- Use Copilot for signal handling code
- Use Claude for shutdown sequence review

**Verification**:
- Server shuts down cleanly
- No data loss during shutdown
- Clients receive shutdown notification
- Resources are properly released

---

## Phase 4: Testing & Documentation

**Goal**: Comprehensive testing and documentation  
**Duration**: 2-3 days  
**Status**: ⏳ Not Started

### Task 4.1: Unit Tests
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 8 hours  
**Dependencies**: All implementation tasks

**Description**:
Achieve >80% unit test coverage for all packages.

**Acceptance Criteria**:
- [ ] Unit tests for domain models (>90% coverage)
- [ ] Unit tests for application services (>85% coverage)
- [ ] Unit tests for message handlers (>80% coverage)
- [ ] Use table-driven tests where appropriate
- [ ] Mock external dependencies
- [ ] Run tests with race detector

**Implementation Steps**:
1. Write tests for each package in `*_test.go` files
2. Use testify/mock for mocking
3. Create test fixtures and helpers
4. Run `go test -cover ./...` to check coverage
5. Run `go test -race ./...` to detect races
6. Generate coverage report: `go test -coverprofile=coverage.out`

**AI Collaboration**:
- Use Copilot to generate test cases
- Use Claude to suggest edge cases

**Verification**:
- Coverage >80% overall
- All tests pass
- No race conditions detected

---

### Task 4.2: Integration Tests
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 6 hours  
**Dependencies**: Phase 2 complete

**Description**:
Write integration tests using testcontainers for Redis and PostgreSQL.

**Acceptance Criteria**:
- [ ] Install testcontainers-go
- [ ] Create integration test suite
- [ ] Test with real Redis and PostgreSQL containers
- [ ] Test complete user flows (join, answer, leaderboard)
- [ ] Test multi-user scenarios
- [ ] Test failure scenarios

**Implementation Steps**:
1. Install: `go get github.com/testcontainers/testcontainers-go`
2. Create `/test/integration/setup_test.go` with container startup
3. Write integration test scenarios:
   - User join flow
   - Answer submission flow
   - Leaderboard updates
   - Cross-instance messaging
4. Use `testing.T` cleanup for container teardown

**AI Collaboration**:
- Use Copilot for testcontainers setup
- Use Claude for test scenario design

**Verification**:
- All integration tests pass
- Tests run in CI environment
- Containers start/stop correctly

---

### Task 4.3: Load Testing
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 4 hours  
**Dependencies**: Phase 2 complete

**Description**:
Create load tests to validate performance targets.

**Acceptance Criteria**:
- [ ] Install k6 or Artillery
- [ ] Create load test scripts
- [ ] Test 1,000 concurrent connections
- [ ] Test 10,000 concurrent connections
- [ ] Measure latency (P50, P95, P99)
- [ ] Measure throughput (messages/second)
- [ ] Generate performance report

**Implementation Steps**:
1. Install k6: `brew install k6`
2. Create `/test/load/websocket_test.js`:
   ```javascript
   import ws from 'k6/ws';
   export default function () {
       const url = 'ws://localhost:8080/ws';
       ws.connect(url, function (socket) {
           socket.on('open', () => {
               socket.send(JSON.stringify({type: 'JOIN_SESSION', ...}));
           });
       });
   }
   ```
3. Run tests with increasing load
4. Collect metrics from Prometheus
5. Generate report with charts

**AI Collaboration**:
- Use Claude for load test strategy
- Use Copilot for k6 script generation

**Verification**:
- Server handles 10,000 connections
- Latency meets targets (P99 <200ms)
- No errors under load
- Resource usage is acceptable

---

### Task 4.4: API Documentation
**Status**: ⏳ Not Started  
**Priority**: Medium  
**Estimated Time**: 3 hours  
**Dependencies**: All implementation complete

**Description**:
Create comprehensive API documentation.

**Acceptance Criteria**:
- [ ] Document WebSocket message protocol
- [ ] Document REST endpoints (/health, /metrics)
- [ ] Provide message examples (request/response)
- [ ] Document error codes and messages
- [ ] Create API reference in Markdown
- [ ] Add Postman/Insomnia collection (optional)

**Implementation Steps**:
1. Create `/docs/API.md`
2. Document each message type with examples
3. Document error responses
4. Create sequence diagrams for flows
5. Add authentication notes (even if mocked)
6. Export Postman collection if created

**AI Collaboration**:
- Use Claude to review documentation clarity
- Use Copilot for example generation

**Verification**:
- Documentation is clear and complete
- All message types are documented
- Examples are accurate

---

### Task 4.5: Deployment Guide
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 4 hours  
**Dependencies**: All tasks complete

**Description**:
Create deployment guide with Docker Compose and Kubernetes examples.

**Acceptance Criteria**:
- [ ] Document Docker Compose setup
- [ ] Create Kubernetes manifests (Deployment, Service, ConfigMap)
- [ ] Document environment variables
- [ ] Create deployment checklist
- [ ] Add troubleshooting guide
- [ ] Document monitoring setup

**Implementation Steps**:
1. Create `/docs/DEPLOYMENT.md`
2. Document Docker Compose usage:
   ```bash
   docker-compose up --scale server=3
   ```
3. Create `/k8s/` directory with Kubernetes manifests
4. Document configuration options
5. Add common troubleshooting scenarios
6. Document Prometheus/Grafana setup

**AI Collaboration**:
- Use Copilot for Kubernetes manifests
- Use Claude for deployment best practices

**Verification**:
- Deployment guide is complete
- Commands work as documented
- Kubernetes manifests are valid

---

### Task 4.6: AI Collaboration Documentation
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 3 hours  
**Dependencies**: All tasks complete

**Description**:
Document AI collaboration throughout the project (required by challenge).

**Acceptance Criteria**:
- [ ] Create AI_COLLABORATION.md
- [ ] Document AI tools used (Copilot, Claude, ChatGPT)
- [ ] List code sections generated/assisted by AI
- [ ] Document prompts and interactions
- [ ] Describe verification process for AI code
- [ ] Add code comments marking AI-assisted sections
- [ ] Document challenges and limitations

**Implementation Steps**:
1. Create `/docs/AI_COLLABORATION.md`
2. Review all code for AI-assisted sections
3. Add comments: `// AI-Generated: GitHub Copilot - [description]`
4. Document specific examples:
   - Prompt used
   - Code generated
   - Modifications made
   - Testing performed
5. Document overall workflow with AI
6. Describe value added and time saved

**AI Collaboration**:
- Use Claude to review documentation completeness
- Reflect on this entire project's AI usage

**Verification**:
- All AI usage is documented
- Verification process is clear
- Examples are specific and detailed

---

### Task 4.7: README and Project Documentation
**Status**: ⏳ Not Started  
**Priority**: High  
**Estimated Time**: 2 hours  
**Dependencies**: All tasks complete

**Description**:
Create comprehensive README and project overview documentation.

**Acceptance Criteria**:
- [ ] Update README.md with project overview
- [ ] Add quick start guide
- [ ] Document project structure
- [ ] Add links to all documentation
- [ ] Include screenshots/demos
- [ ] Add badges (build status, coverage)
- [ ] Document development workflow

**Implementation Steps**:
1. Update `/README.md` with:
   - Project description
   - Features
   - Quick start (5-minute setup)
   - Architecture overview
   - Links to docs
   - Contributing guidelines
2. Add architecture diagram
3. Add demo GIF or screenshots
4. Document make targets

**AI Collaboration**:
- Use Claude to review README clarity
- Use Copilot for quick start commands

**Verification**:
- README is clear and informative
- Quick start works for new users
- All links are valid

---

## Phase 5: Video Presentation

**Goal**: Create 5-10 minute video presentation  
**Duration**: 1 day  
**Status**: ⏳ Not Started

### Task 5.1: Video Script
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 2 hours  
**Dependencies**: All previous phases complete

**Description**:
Write script for video presentation covering all required points.

**Acceptance Criteria**:
- [ ] Introduction (30 seconds)
- [ ] Assignment overview (1 minute)
- [ ] Solution architecture (2 minutes)
- [ ] AI collaboration story (1-2 minutes)
- [ ] Live demo (3-4 minutes)
- [ ] Conclusion (30 seconds)
- [ ] Total time: 5-10 minutes
- [ ] Script reviewed and timed

**Implementation Steps**:
1. Create `/docs/VIDEO_SCRIPT.md`
2. Write introduction and self-intro
3. Outline solution highlights
4. Prepare AI collaboration narrative with examples
5. Plan demo scenarios
6. Write conclusion with learnings
7. Time each section

**AI Collaboration**:
- Use Claude to review script structure
- Get feedback on AI collaboration narrative

**Verification**:
- Script covers all required points
- Timing fits 5-10 minute constraint
- Flow is logical and engaging

---

### Task 5.2: Demo Preparation
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 2 hours  
**Dependencies**: Task 5.1

**Description**:
Prepare demo environment and scenarios for video recording.

**Acceptance Criteria**:
- [ ] Set up clean demo environment
- [ ] Prepare demo data (quiz, users)
- [ ] Create demo script (commands, actions)
- [ ] Test demo flow multiple times
- [ ] Prepare code examples to show
- [ ] Set up screen layout (terminal, browser, code)

**Implementation Steps**:
1. Create fresh Docker environment
2. Prepare demo quiz with interesting questions
3. Create script for demo actions:
   - Start server
   - Show multiple clients joining
   - Submit answers
   - Show leaderboard updates
   - Show metrics/logs
4. Practice demo multiple times
5. Prepare code snippets to highlight

**Verification**:
- Demo runs smoothly
- All features are showcased
- Timing fits within video constraints

---

### Task 5.3: Video Recording & Editing
**Status**: ⏳ Not Started  
**Priority**: Critical  
**Estimated Time**: 3 hours  
**Dependencies**: Task 5.2

**Description**:
Record and edit video presentation.

**Acceptance Criteria**:
- [ ] Record video (720p or 1080p)
- [ ] Clear audio quality
- [ ] Show face and screen
- [ ] Execute demo smoothly
- [ ] Cover all script points
- [ ] Edit for clarity (remove mistakes)
- [ ] Add subtitles (optional but recommended)
- [ ] Export final video (MP4)

**Implementation Steps**:
1. Set up recording software (OBS, Zoom, etc.)
2. Test audio and video quality
3. Record multiple takes if needed
4. Edit video:
   - Cut mistakes
   - Add transitions
   - Highlight important points
   - Add text overlays for AI tools used
5. Export final video
6. Review and validate quality

**Verification**:
- Video length: 5-10 minutes
- Audio is clear
- Demo is visible and understandable
- All requirements addressed

---

## Summary

**Total Tasks**: 42  
**Estimated Total Time**: 100-120 hours (2-3 weeks full-time)

**Critical Path**:
1. Phase 1 (Foundation) → Phase 2 (Scaling) → Phase 3 (Observability) → Phase 4 (Testing) → Phase 5 (Video)
2. Must complete each phase before proceeding to next

**Key Milestones**:
- ✅ Phase 1 Complete: Working MVP with in-memory state
- ✅ Phase 2 Complete: Scalable multi-instance system
- ✅ Phase 3 Complete: Production-ready observability
- ✅ Phase 4 Complete: Tested and documented
- ✅ Phase 5 Complete: Video presentation ready for submission

---

**Last Updated**: November 16, 2025  
**Next Task**: Task 1.1 - Project Setup & Structure

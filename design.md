# System Design - Real-Time Vocabulary Quiz System

**Last Updated**: November 16, 2025  
**Status**: Initial Design  
**Design Confidence**: 78% (Medium-High)

## Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Component Selection](#2-component-selection)
3. [Technology Stack](#3-technology-stack)
4. [Detailed Component Design](#4-detailed-component-design)
5. [Data Models](#5-data-models)
6. [API Contracts](#6-api-contracts)
7. [Data Flow](#7-data-flow)
8. [Scalability Design](#8-scalability-design)
9. [Performance Optimization](#9-performance-optimization)
10. [Reliability & Error Handling](#10-reliability--error-handling)
11. [Monitoring & Observability](#11-monitoring--observability)
12. [Security Considerations](#12-security-considerations)
13. [Implementation Plan](#13-implementation-plan)

---

## 1. Architecture Overview

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT TIER                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Web Client  │  │  Web Client  │  │  Web Client  │  ...     │
│  │  (Mocked)    │  │  (Mocked)    │  │  (Mocked)    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
└─────────┼──────────────────┼──────────────────┼──────────────────┘
          │                  │                  │
          │  WebSocket       │  WebSocket       │  WebSocket
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼──────────────────┐
│         ▼                  ▼                  ▼                   │
│  ┌─────────────────────────────────────────────────────┐         │
│  │           Load Balancer / API Gateway                │         │
│  │         (Sticky Sessions for WebSockets)             │         │
│  └─────────────────────────────────────────────────────┘         │
│                              │                                    │
│         ┌────────────────────┼────────────────────┐              │
│         │                    │                    │              │
│         ▼                    ▼                    ▼              │
│  ┌──────────┐        ┌──────────┐        ┌──────────┐           │
│  │  Server  │        │  Server  │        │  Server  │           │
│  │Instance 1│        │Instance 2│        │Instance N│           │
│  │          │        │          │        │          │           │
│  │ ┌──────┐ │        │ ┌──────┐ │        │ ┌──────┐ │           │
│  │ │ WS   │ │        │ │ WS   │ │        │ │ WS   │ │           │
│  │ │Handler│ │       │ │Handler│ │        │ │Handler│ │          │
│  │ └──────┘ │        │ └──────┘ │        │ └──────┘ │           │
│  │ ┌──────┐ │        │ ┌──────┐ │        │ ┌──────┐ │           │
│  │ │Score │ │        │ │Score │ │        │ │Score │ │           │
│  │ │Engine│ │        │ │Engine│ │        │ │Engine│ │           │
│  │ └──────┘ │        │ └──────┘ │        │ └──────┘ │           │
│  │ ┌──────┐ │        │ ┌──────┐ │        │ ┌──────┐ │           │
│  │ │Leader│ │        │ │Leader│ │        │ │Leader│ │           │
│  │ │board │ │        │ │board │ │        │ │board │ │           │
│  │ └──────┘ │        │ └──────┘ │        │ └──────┘ │           │
│  └────┬─────┘        └────┬─────┘        └────┬─────┘           │
│       │                   │                   │                  │
│       └───────────────────┼───────────────────┘                  │
│                           │                                      │
│                  SERVER TIER (IMPLEMENTED)                       │
└───────────────────────────┼──────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Redis      │    │  PostgreSQL  │    │  Pub/Sub     │
│  (Cache &    │    │  (Primary    │    │  (Message    │
│   Session)   │    │   Storage)   │    │   Broker)    │
└──────────────┘    └──────────────┘    └──────────────┘
                            │
                  DATA TIER (MOCKED)
```

### 1.2 Architectural Principles

- **Separation of Concerns**: Clear boundaries between WebSocket handling, business logic, and data access
- **Stateless Services**: Server instances are stateless; state is externalized to Redis/Database
- **Event-Driven**: Use pub/sub for cross-instance communication
- **Fail-Fast**: Validate early, fail explicitly with clear error messages
- **Horizontal Scalability**: Design supports adding server instances without code changes

### 1.3 Component Layers (DDD-Inspired)

```
┌────────────────────────────────────────────────┐
│          PRESENTATION LAYER                    │
│  - WebSocket Handlers                          │
│  - Message Parsers/Serializers                 │
│  - Connection Manager                          │
└────────────────┬───────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────┐
│          APPLICATION LAYER                     │
│  - Quiz Session Service                        │
│  - Scoring Service                             │
│  - Leaderboard Service                         │
│  - User Session Service                        │
└────────────────┬───────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────┐
│          DOMAIN LAYER                          │
│  - Quiz Session (Aggregate)                    │
│  - Participant (Entity)                        │
│  - Score (Value Object)                        │
│  - Answer (Entity)                             │
│  - Domain Events (ScoreUpdated, etc.)          │
└────────────────┬───────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────┐
│          INFRASTRUCTURE LAYER                  │
│  - Redis Repository                            │
│  - PostgreSQL Repository                       │
│  - Pub/Sub Client                              │
│  - Metrics Collector                           │
└────────────────────────────────────────────────┘
```

---

## 2. Component Selection

### 2.1 Implementation Choice: **Real-Time Quiz Server**

**Rationale**:
- Server is the **core orchestrator** of real-time interactions
- Demonstrates all critical requirements: concurrency, scoring, leaderboard, real-time communication
- More complex than client, showcasing better engineering depth
- Enables testing with multiple simulated clients
- Server-side performance optimization is more critical for scalability

### 2.2 Mocked Components

The following components will be **mocked or simulated**:

1. **Client Applications**
   - Simple test clients for validation
   - Simulate multiple concurrent users
   - Mock WebSocket connections

2. **Quiz Content Service**
   - Static JSON files with predefined questions/answers
   - Simple in-memory quiz repository

3. **User Authentication**
   - Basic user ID assignment (no real auth)
   - Session tokens generated on connection

4. **Database Layer** (Partial Mock)
   - Redis mock for caching
   - In-memory storage option for development
   - PostgreSQL schema defined but can use in-memory substitute

---

## 3. Technology Stack

### 3.1 Server Implementation

**Language**: **Go (Golang)**

**Rationale**:
- **High Performance**: Excellent for concurrent WebSocket connections (goroutines)
- **Low Latency**: Native compiled language, minimal GC pauses
- **Built-in Concurrency**: Channels and goroutines perfect for real-time systems
- **Strong Standard Library**: HTTP/WebSocket support, JSON handling
- **Production-Ready**: Used by many high-scale real-time systems (Discord, Twitch chat backend)
- **Easy Deployment**: Single binary, simple containerization

**Key Libraries**:
```go
- gorilla/websocket    // WebSocket server implementation
- gin-gonic/gin        // HTTP router and middleware (lightweight)
- go-redis/redis       // Redis client
- lib/pq               // PostgreSQL driver
- prometheus/client_go // Metrics collection
- uber-go/zap          // High-performance logging
- stretchr/testify     // Testing framework
```

### 3.2 Real-Time Communication

**Protocol**: **WebSocket** (over WSS in production)

**Rationale**:
- Full-duplex, persistent connection ideal for bidirectional real-time updates
- Lower latency than HTTP polling or SSE
- Efficient message framing
- Wide browser support
- Native support in Go

**Message Format**: **JSON** (with potential binary protocol upgrade path)

### 3.3 Data Storage

**Primary Database**: **PostgreSQL** (Mocked with in-memory option)

**Rationale**:
- ACID compliance for score consistency
- Rich querying for leaderboard calculations
- JSON support for flexible schema
- Proven at scale

**Caching Layer**: **Redis**

**Rationale**:
- In-memory speed for session state
- Pub/Sub for cross-instance messaging
- Leaderboard sorted sets (ZADD, ZRANGE)
- TTL support for session expiry
- Atomic operations for score updates

### 3.4 Message Broker

**Pub/Sub**: **Redis Pub/Sub**

**Rationale**:
- Simple integration with Redis cache
- Low latency for local deployments
- Sufficient for moderate scale
- Easy to upgrade to Kafka/RabbitMQ later

### 3.5 Monitoring & Observability

**Metrics**: **Prometheus** + **Grafana**

**Logging**: **Uber Zap** (structured JSON logs)

**Tracing**: **OpenTelemetry** (basic implementation)

**Health Checks**: **Custom /health endpoint**

### 3.6 Development & Testing

**Testing**: 
- Unit tests: Go testing package + testify
- Integration tests: Testcontainers for Redis/PostgreSQL
- Load testing: k6 or Artillery

**Containerization**: **Docker** + **Docker Compose**

**Code Quality**: 
- golangci-lint (static analysis)
- gofmt (formatting)
- go vet (error checking)

---

## 4. Detailed Component Design

### 4.1 WebSocket Connection Manager

**Responsibilities**:
- Accept and manage WebSocket connections
- Authenticate users (basic validation)
- Route messages to appropriate handlers
- Broadcast messages to participants
- Handle connection lifecycle (connect, disconnect, reconnect)

**Design**:
```go
type ConnectionManager struct {
    connections map[string]*websocket.Conn  // userID -> connection
    sessions    map[string][]string          // sessionID -> userIDs
    mutex       sync.RWMutex                 // Thread-safe access
    upgrader    websocket.Upgrader
    pubsub      *redis.PubSubClient
}

// Key Methods
func (cm *ConnectionManager) HandleConnection(w http.ResponseWriter, r *http.Request)
func (cm *ConnectionManager) SendToUser(userID string, message Message) error
func (cm *ConnectionManager) BroadcastToSession(sessionID string, message Message) error
func (cm *ConnectionManager) RemoveConnection(userID string)
```

**Concurrency Model**:
- Each WebSocket connection runs in a dedicated goroutine
- Read/write goroutines per connection to prevent blocking
- Channel-based message passing for thread safety

### 4.2 Quiz Session Service

**Responsibilities**:
- Create and manage quiz sessions
- Track participants in sessions
- Enforce session lifecycle (waiting → active → completed)
- Validate quiz IDs

**Design**:
```go
type QuizSession struct {
    SessionID    string
    QuizID       string
    Participants map[string]*Participant
    Status       SessionStatus
    StartTime    time.Time
    EndTime      *time.Time
    mu           sync.RWMutex
}

type SessionService struct {
    sessions map[string]*QuizSession
    cache    *redis.Client
    repo     SessionRepository
}

// Key Methods
func (s *SessionService) CreateSession(quizID string) (*QuizSession, error)
func (s *SessionService) JoinSession(sessionID, userID string) error
func (s *SessionService) GetSession(sessionID string) (*QuizSession, error)
func (s *SessionService) LeaveSession(sessionID, userID string) error
```

### 4.3 Scoring Engine

**Responsibilities**:
- Validate answer submissions
- Calculate scores based on correctness
- Apply scoring rules (points per question, time bonus, etc.)
- Emit score update events
- Ensure atomic score updates

**Design**:
```go
type ScoringEngine struct {
    quizRepo    QuizRepository
    scoreRepo   ScoreRepository
    cache       *redis.Client
    eventBus    EventBus
}

// Key Methods
func (se *ScoringEngine) SubmitAnswer(ctx context.Context, submission AnswerSubmission) (*ScoreResult, error)
func (se *ScoringEngine) ValidateAnswer(submission AnswerSubmission) (bool, error)
func (se *ScoringEngine) CalculatePoints(isCorrect bool, timeTaken time.Duration) int
func (se *ScoringEngine) UpdateScore(userID, sessionID string, points int) error
```

**Scoring Algorithm**:
```
Base Points: 10 per correct answer
Time Bonus: max(0, 5 - floor(timeTaken/2seconds)) 
Total: basePoints + timeBonus (if correct), 0 (if incorrect)
```

**Atomicity**:
- Use Redis INCR for atomic score updates
- Optimistic locking for database writes
- Event sourcing pattern for audit trail

### 4.4 Leaderboard Service

**Responsibilities**:
- Maintain real-time rankings
- Calculate leaderboard positions
- Broadcast leaderboard updates
- Support pagination for large sessions

**Design**:
```go
type LeaderboardService struct {
    cache      *redis.Client
    repo       LeaderboardRepository
    pubsub     *redis.PubSubClient
}

// Key Methods
func (ls *LeaderboardService) UpdateRanking(sessionID, userID string, newScore int) error
func (ls *LeaderboardService) GetLeaderboard(sessionID string, limit, offset int) ([]LeaderboardEntry, error)
func (ls *LeaderboardService) BroadcastUpdate(sessionID string) error
```

**Data Structure**:
- Redis Sorted Set: `leaderboard:{sessionID}` with score as sort key
- Cache TTL: Session duration + 1 hour
- Update strategy: Incremental updates on score change

**Optimization**:
- Batch updates (100ms window) to reduce broadcast frequency
- Paginated leaderboard (top 100 by default)
- Delta updates (only changed rankings) for efficiency

### 4.5 Event Bus

**Responsibilities**:
- Publish domain events (ScoreUpdated, UserJoined, SessionEnded)
- Subscribe to events across server instances
- Ensure event ordering per session

**Design**:
```go
type EventBus struct {
    pubsub *redis.PubSubClient
}

type DomainEvent struct {
    Type      EventType
    SessionID string
    Payload   interface{}
    Timestamp time.Time
}

// Key Methods
func (eb *EventBus) Publish(event DomainEvent) error
func (eb *EventBus) Subscribe(eventType EventType, handler EventHandler) error
```

**Event Types**:
- `USER_JOINED`: User joins session
- `USER_LEFT`: User leaves/disconnects
- `ANSWER_SUBMITTED`: Answer submitted
- `SCORE_UPDATED`: Score changed
- `LEADERBOARD_UPDATED`: Rankings changed
- `SESSION_STARTED`: Quiz begins
- `SESSION_ENDED`: Quiz completes

---

## 5. Data Models

### 5.1 Domain Models

**QuizSession**
```go
type QuizSession struct {
    ID           string       `json:"id" db:"id"`
    QuizID       string       `json:"quiz_id" db:"quiz_id"`
    Status       string       `json:"status" db:"status"` // waiting|active|completed
    StartTime    time.Time    `json:"start_time" db:"start_time"`
    EndTime      *time.Time   `json:"end_time,omitempty" db:"end_time"`
    MaxParticipants int       `json:"max_participants" db:"max_participants"`
    CreatedAt    time.Time    `json:"created_at" db:"created_at"`
}
```

**Participant**
```go
type Participant struct {
    ID           string    `json:"id" db:"id"`
    UserID       string    `json:"user_id" db:"user_id"`
    SessionID    string    `json:"session_id" db:"session_id"`
    Username     string    `json:"username" db:"username"`
    Score        int       `json:"score" db:"score"`
    JoinedAt     time.Time `json:"joined_at" db:"joined_at"`
    LastActiveAt time.Time `json:"last_active_at" db:"last_active_at"`
    Status       string    `json:"status" db:"status"` // connected|disconnected
}
```

**AnswerSubmission**
```go
type AnswerSubmission struct {
    ID           string    `json:"id" db:"id"`
    UserID       string    `json:"user_id" db:"user_id"`
    SessionID    string    `json:"session_id" db:"session_id"`
    QuestionID   string    `json:"question_id" db:"question_id"`
    Answer       string    `json:"answer" db:"answer"`
    IsCorrect    bool      `json:"is_correct" db:"is_correct"`
    Points       int       `json:"points" db:"points"`
    SubmittedAt  time.Time `json:"submitted_at" db:"submitted_at"`
    TimeTaken    int       `json:"time_taken_ms" db:"time_taken_ms"` // milliseconds
}
```

**LeaderboardEntry**
```go
type LeaderboardEntry struct {
    Rank      int    `json:"rank"`
    UserID    string `json:"user_id"`
    Username  string `json:"username"`
    Score     int    `json:"score"`
    UpdatedAt time.Time `json:"updated_at"`
}
```

**Quiz** (Mocked)
```go
type Quiz struct {
    ID          string     `json:"id"`
    Title       string     `json:"title"`
    Questions   []Question `json:"questions"`
}

type Question struct {
    ID            string   `json:"id"`
    Text          string   `json:"text"`
    Options       []string `json:"options,omitempty"`
    CorrectAnswer string   `json:"correct_answer"`
    Points        int      `json:"points"`
}
```

### 5.2 Database Schema

**PostgreSQL Tables**:

```sql
-- Quiz Sessions
CREATE TABLE quiz_sessions (
    id VARCHAR(36) PRIMARY KEY,
    quiz_id VARCHAR(36) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('waiting', 'active', 'completed')),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    max_participants INT DEFAULT 1000,
    created_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_quiz_id (quiz_id),
    INDEX idx_status (status)
);

-- Participants
CREATE TABLE participants (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    session_id VARCHAR(36) NOT NULL REFERENCES quiz_sessions(id),
    username VARCHAR(100) NOT NULL,
    score INT DEFAULT 0,
    joined_at TIMESTAMP DEFAULT NOW(),
    last_active_at TIMESTAMP DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'connected',
    INDEX idx_session_user (session_id, user_id),
    INDEX idx_user_id (user_id),
    UNIQUE(session_id, user_id)
);

-- Answer Submissions
CREATE TABLE answer_submissions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    session_id VARCHAR(36) NOT NULL REFERENCES quiz_sessions(id),
    question_id VARCHAR(36) NOT NULL,
    answer TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    points INT NOT NULL,
    submitted_at TIMESTAMP DEFAULT NOW(),
    time_taken_ms INT,
    INDEX idx_session_user (session_id, user_id),
    INDEX idx_question (question_id)
);

-- Leaderboard (Materialized View - Optional)
CREATE MATERIALIZED VIEW leaderboard_snapshot AS
SELECT 
    session_id,
    user_id,
    username,
    score,
    RANK() OVER (PARTITION BY session_id ORDER BY score DESC, joined_at ASC) as rank,
    NOW() as snapshot_time
FROM participants
WHERE status = 'connected';

CREATE INDEX idx_leaderboard_session ON leaderboard_snapshot(session_id, rank);
```

### 5.3 Redis Data Structures

```
# Session State
Key: session:{sessionID}
Type: Hash
Fields: {quiz_id, status, start_time, participant_count}
TTL: 24 hours

# Participant Connection State
Key: participant:{sessionID}:{userID}
Type: Hash
Fields: {username, score, last_active, status}
TTL: Session duration + 1 hour

# Leaderboard
Key: leaderboard:{sessionID}
Type: Sorted Set
Members: userID
Scores: user score
TTL: Session duration + 1 hour

# Active Connections
Key: connections:{serverID}
Type: Set
Members: userID list
TTL: 5 minutes (refreshed via heartbeat)

# Session Lock (for atomic operations)
Key: lock:session:{sessionID}
Type: String
TTL: 5 seconds
```

---

## 6. API Contracts

### 6.1 WebSocket Message Protocol

**Connection**:
```
Endpoint: ws://localhost:8080/ws
Query Params: ?user_id={userId}
```

**Message Format**:
```json
{
  "type": "MESSAGE_TYPE",
  "payload": {...},
  "timestamp": "2025-11-16T10:30:00Z",
  "message_id": "uuid"
}
```

### 6.2 Client → Server Messages

**1. Join Session**
```json
{
  "type": "JOIN_SESSION",
  "payload": {
    "session_id": "quiz-123",
    "username": "john_doe"
  }
}
```

**2. Submit Answer**
```json
{
  "type": "SUBMIT_ANSWER",
  "payload": {
    "session_id": "quiz-123",
    "question_id": "q1",
    "answer": "Paris",
    "time_taken_ms": 3500
  }
}
```

**3. Leave Session**
```json
{
  "type": "LEAVE_SESSION",
  "payload": {
    "session_id": "quiz-123"
  }
}
```

**4. Heartbeat**
```json
{
  "type": "PING",
  "payload": {}
}
```

### 6.3 Server → Client Messages

**1. Session Joined**
```json
{
  "type": "SESSION_JOINED",
  "payload": {
    "session_id": "quiz-123",
    "quiz_id": "vocab-101",
    "status": "active",
    "participant_count": 15,
    "your_score": 0
  }
}
```

**2. Score Update**
```json
{
  "type": "SCORE_UPDATED",
  "payload": {
    "user_id": "user-456",
    "new_score": 25,
    "points_earned": 15,
    "is_correct": true,
    "question_id": "q1"
  }
}
```

**3. Leaderboard Update**
```json
{
  "type": "LEADERBOARD_UPDATED",
  "payload": {
    "session_id": "quiz-123",
    "leaderboard": [
      {"rank": 1, "user_id": "user-123", "username": "alice", "score": 50},
      {"rank": 2, "user_id": "user-456", "username": "bob", "score": 45},
      {"rank": 3, "user_id": "user-789", "username": "carol", "score": 40}
    ],
    "your_rank": 2,
    "total_participants": 15
  }
}
```

**4. User Joined**
```json
{
  "type": "USER_JOINED",
  "payload": {
    "user_id": "user-999",
    "username": "dave",
    "participant_count": 16
  }
}
```

**5. User Left**
```json
{
  "type": "USER_LEFT",
  "payload": {
    "user_id": "user-999",
    "username": "dave",
    "participant_count": 15
  }
}
```

**6. Error**
```json
{
  "type": "ERROR",
  "payload": {
    "code": "INVALID_SESSION",
    "message": "Session quiz-999 does not exist",
    "recoverable": false
  }
}
```

**7. Pong (Heartbeat Response)**
```json
{
  "type": "PONG",
  "payload": {
    "server_time": "2025-11-16T10:30:05Z"
  }
}
```

### 6.4 REST API (Admin/Health)

**Health Check**
```
GET /health
Response: 200 OK
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime_seconds": 3600,
  "active_connections": 150,
  "active_sessions": 12
}
```

**Metrics**
```
GET /metrics
Response: 200 OK (Prometheus format)
```

**Create Session** (Admin)
```
POST /api/v1/sessions
Request:
{
  "quiz_id": "vocab-101",
  "max_participants": 1000
}

Response: 201 Created
{
  "session_id": "quiz-123",
  "quiz_id": "vocab-101",
  "status": "waiting"
}
```

---

## 7. Data Flow

### 7.1 User Join Flow

```
┌────────┐                ┌────────┐              ┌─────────┐          ┌─────────┐
│ Client │                │ Server │              │  Redis  │          │   DB    │
└───┬────┘                └───┬────┘              └────┬────┘          └────┬────┘
    │                         │                        │                    │
    │ 1. WebSocket Connect    │                        │                    │
    │────────────────────────>│                        │                    │
    │                         │                        │                    │
    │ 2. JOIN_SESSION         │                        │                    │
    │────────────────────────>│                        │                    │
    │                         │                        │                    │
    │                         │ 3. Validate Session    │                    │
    │                         │──────────────────────> │                    │
    │                         │                        │                    │
    │                         │ 4. Session Exists      │                    │
    │                         │ <──────────────────────│                    │
    │                         │                        │                    │
    │                         │ 5. Add Participant     │                    │
    │                         │──────────────────────────────────────────> │
    │                         │                        │                    │
    │                         │ 6. Update Session Cache│                    │
    │                         │──────────────────────> │                    │
    │                         │                        │                    │
    │                         │ 7. Publish USER_JOINED │                    │
    │                         │──────────────────────> │                    │
    │                         │                        │                    │
    │ 8. SESSION_JOINED       │                        │                    │
    │ <───────────────────────│                        │                    │
    │                         │                        │                    │
    │ 9. USER_JOINED (broadcast to others)             │                    │
    │ <───────────────────────│                        │                    │
    │                         │                        │                    │
```

**Steps**:
1. Client establishes WebSocket connection with user_id query param
2. Client sends JOIN_SESSION message with session_id and username
3. Server validates session exists in Redis cache
4. Redis confirms session exists and status is "active" or "waiting"
5. Server creates participant record in PostgreSQL
6. Server updates session participant count in Redis
7. Server publishes USER_JOINED event to Redis Pub/Sub
8. Server sends SESSION_JOINED confirmation to the joining client
9. All other clients in the session receive USER_JOINED broadcast

**Error Scenarios**:
- Invalid session_id → ERROR response: "Session not found"
- Session full → ERROR response: "Session at capacity"
- User already joined → Reconnect logic (update connection reference)

### 7.2 Answer Submission Flow

```
┌────────┐          ┌────────┐        ┌─────────┐        ┌─────────┐         ┌────────────┐
│ Client │          │ Server │        │  Redis  │        │   DB    │         │Other Clients│
└───┬────┘          └───┬────┘        └────┬────┘        └────┬────┘         └──────┬─────┘
    │                   │                   │                  │                     │
    │ 1. SUBMIT_ANSWER  │                   │                  │                     │
    │──────────────────>│                   │                  │                     │
    │                   │                   │                  │                     │
    │                   │ 2. Validate Question                 │                     │
    │                   │ (from cache/mock) │                  │                     │
    │                   │                   │                  │                     │
    │                   │ 3. Check Answer   │                  │                     │
    │                   │ Correctness       │                  │                     │
    │                   │                   │                  │                     │
    │                   │ 4. Calculate Score│                  │                     │
    │                   │   (base + time)   │                  │                     │
    │                   │                   │                  │                     │
    │                   │ 5. Atomic Score Update (INCRBY)      │                     │
    │                   │──────────────────>│                  │                     │
    │                   │                   │                  │                     │
    │                   │ 6. New Score      │                  │                     │
    │                   │<──────────────────│                  │                     │
    │                   │                   │                  │                     │
    │                   │ 7. Persist Answer │                  │                     │
    │                   │──────────────────────────────────────>│                     │
    │                   │                   │                  │                     │
    │                   │ 8. Update Leaderboard (ZADD)         │                     │
    │                   │──────────────────>│                  │                     │
    │                   │                   │                  │                     │
    │                   │ 9. Publish SCORE_UPDATED             │                     │
    │                   │──────────────────>│                  │                     │
    │                   │                   │                  │                     │
    │ 10. SCORE_UPDATED │                   │                  │                     │
    │<──────────────────│                   │                  │                     │
    │                   │                   │                  │                     │
    │                   │ 11. Publish LEADERBOARD_UPDATED      │                     │
    │                   │──────────────────>│                  │                     │
    │                   │                   │                  │                     │
    │ 12. LEADERBOARD_UPDATED                                  │                     │
    │<──────────────────│                   │                  │                     │
    │                   │                   │                  │                     │
    │                   │ 13. Broadcast to Session             │                     │
    │                   │──────────────────────────────────────────────────────────>│
    │                   │                   │                  │                     │
```

**Steps**:
1. Client submits answer with question_id, answer, and time_taken_ms
2. Server retrieves correct answer from quiz repository (mocked/cached)
3. Server validates answer correctness
4. Server calculates points (base points + time bonus if correct)
5. Server atomically increments user score in Redis using INCRBY
6. Redis returns new total score
7. Server persists answer submission to PostgreSQL (async)
8. Server updates leaderboard sorted set in Redis using ZADD
9. Server publishes SCORE_UPDATED event to Redis Pub/Sub
10. Server sends SCORE_UPDATED message to submitting client
11. Server publishes LEADERBOARD_UPDATED event (may be batched)
12. Server sends updated leaderboard to submitting client
13. All other clients in session receive score and leaderboard updates

**Optimizations**:
- Steps 7 (DB persist) happens asynchronously to reduce latency
- Leaderboard broadcasts are batched (100ms window) to reduce traffic
- Only top 100 leaderboard entries sent to clients

### 7.3 Leaderboard Update Flow

```
┌────────────┐        ┌────────────┐        ┌─────────┐
│  Server    │        │   Redis    │        │ Clients │
│  Instance  │        │  Pub/Sub   │        │ (All)   │
└─────┬──────┘        └─────┬──────┘        └────┬────┘
      │                     │                     │
      │ 1. SCORE_UPDATED    │                     │
      │    event received   │                     │
      │                     │                     │
      │ 2. Add to batch     │                     │
      │    (100ms window)   │                     │
      │                     │                     │
      │ 3. Batch timeout    │                     │
      │    reached          │                     │
      │                     │                     │
      │ 4. ZRANGE           │                     │
      │    leaderboard:xyz  │                     │
      │    0 99 WITHSCORES  │                     │
      │────────────────────>│                     │
      │                     │                     │
      │ 5. Top 100 entries  │                     │
      │<────────────────────│                     │
      │                     │                     │
      │ 6. Compute delta    │                     │
      │    (compare with    │                     │
      │     previous)       │                     │
      │                     │                     │
      │ 7. LEADERBOARD_     │                     │
      │    UPDATED          │                     │
      │──────────────────────────────────────────>│
      │                     │                     │
```

**Batching Strategy**:
- Collect score updates for 100ms
- Fetch leaderboard once per batch
- Calculate delta (changed rankings)
- Broadcast minimal update payload

---

## 8. Scalability Design

### 8.1 Horizontal Scaling

**Strategy**: Stateless server instances + centralized state

**Components**:

1. **Load Balancer**
   - Sticky sessions for WebSocket connections
   - Health check integration
   - Round-robin for new connections

2. **Server Instances**
   - Completely stateless
   - All state in Redis/PostgreSQL
   - Auto-scaling based on connection count

3. **Redis Cluster**
   - Master-slave replication
   - Sentinel for failover
   - Cluster mode for partitioning

4. **PostgreSQL**
   - Read replicas for analytics
   - Connection pooling
   - Partitioning by session_id

**Scaling Triggers**:
- Scale out: >5000 connections per instance
- Scale in: <1000 connections per instance
- Target: 70% resource utilization

### 8.2 Session Affinity

**Problem**: WebSocket connections are stateful at transport layer

**Solution**:
- Load balancer uses sticky sessions (based on client IP or session cookie)
- Connection state stored in Redis allows cross-instance failover
- Pub/Sub ensures messages reach correct instance

**Failover Process**:
1. Instance failure detected by load balancer
2. Client reconnects to different instance
3. New instance retrieves session state from Redis
4. Client resumes with minimal disruption

### 8.3 Database Scaling

**Write Path**:
- Async writes to PostgreSQL (non-critical)
- Write-through cache to Redis
- Batch inserts for answer submissions

**Read Path**:
- Redis cache for hot data (sessions, leaderboards)
- Read replicas for analytics queries
- Cache hit ratio target: >95%

**Partitioning Strategy**:
- Partition by `session_id` (hash-based)
- Each partition handles subset of sessions
- Enables horizontal sharding

### 8.4 Message Broker Scaling

**Current**: Redis Pub/Sub (single instance)

**Future**: Kafka/RabbitMQ for higher scale
- Topic per session or partition by session_id
- Consumer groups for parallel processing
- Message persistence and replay

**Capacity Planning**:
- Redis Pub/Sub: ~50K messages/second
- Kafka: ~500K messages/second (if needed)

---

## 9. Performance Optimization

### 9.1 Latency Targets

| Operation | Target | P99 Target |
|-----------|--------|------------|
| Answer submission → Score update | <50ms | <100ms |
| Score update → Client notification | <50ms | <100ms |
| Leaderboard recalculation | <100ms | <200ms |
| User join | <100ms | <200ms |
| WebSocket message roundtrip | <20ms | <50ms |

### 9.2 Optimization Techniques

**1. Connection Pooling**
```go
// Database connection pool
maxOpenConns: 25 per instance
maxIdleConns: 10
connMaxLifetime: 5 minutes

// Redis connection pool
poolSize: 100 per instance
minIdleConns: 10
```

**2. Caching Strategy**
- L1: In-memory LRU cache (5-second TTL for quiz questions)
- L2: Redis cache (session state, leaderboards)
- L3: PostgreSQL (persistent storage)

**3. Message Batching**
- Leaderboard updates: 100ms batch window
- Metrics: 1-second aggregation
- Database writes: 500ms batch window

**4. Goroutine Pooling**
```go
// Worker pool for CPU-intensive tasks
workerPool: 100 workers per instance
taskQueue: buffered channel (capacity: 1000)
```

**5. Zero-Copy Message Passing**
- Use `sync.Pool` for message objects
- Reuse buffers for JSON serialization
- Minimize allocations in hot path

**6. Database Optimizations**
- Prepared statements for common queries
- Indexes on session_id, user_id, question_id
- Materialized views for leaderboard snapshots

### 9.3 Profiling & Benchmarking

**CPU Profiling**:
```bash
go test -cpuprofile=cpu.prof -bench=.
go tool pprof cpu.prof
```

**Memory Profiling**:
```bash
go test -memprofile=mem.prof -bench=.
go tool pprof mem.prof
```

**Load Testing**:
```javascript
// k6 script
export default function() {
  const ws = new WebSocket('ws://localhost:8080/ws?user_id=test');
  ws.on('open', () => {
    ws.send(JSON.stringify({type: 'JOIN_SESSION', payload: {session_id: 'test'}}));
  });
}
```

**Targets**:
- 10,000 concurrent WebSocket connections per instance
- <1% CPU at 1,000 connections
- <500MB memory at 10,000 connections
- 100K messages/second throughput

---

## 10. Reliability & Error Handling

### 10.1 Error Categories

**1. Client Errors (4xx equivalent)**
- Invalid session ID
- Malformed message
- Unauthorized access
- Rate limit exceeded

**Response**: Send ERROR message to client, log warning

**2. Server Errors (5xx equivalent)**
- Database connection failure
- Redis unavailable
- Internal processing error

**Response**: Send ERROR message, retry with exponential backoff, alert monitoring

**3. Network Errors**
- Connection dropped
- Timeout
- Packet loss

**Response**: Client reconnection logic, message replay

### 10.2 Error Handling Matrix

| Error Type | Detection | Response | Recovery | Client Impact |
|------------|-----------|----------|----------|---------------|
| Invalid session ID | Validation | ERROR message | None | User notified |
| Database timeout | Query timeout | Retry 3x, then ERROR | Cache fallback | Temporary degradation |
| Redis unavailable | Connection error | Use in-memory fallback | Auto-reconnect | Degraded real-time |
| WebSocket disconnect | Connection close | Cleanup resources | Client reconnect | Brief interruption |
| Message parse error | JSON unmarshal | ERROR response | Skip message | User notified |
| Rate limit | Request count | 429-style ERROR | Wait period | Temporary block |
| Score conflict | Optimistic lock | Retry with backoff | Resolve conflict | Transparent |

### 10.3 Fault Tolerance

**Circuit Breaker Pattern**:
```go
type CircuitBreaker struct {
    maxFailures  int           // 5 consecutive failures
    timeout      time.Duration // 30 seconds
    state        State         // Closed | Open | HalfOpen
}
```

**Graceful Degradation**:
- Redis unavailable → In-memory session state (single instance)
- Database unavailable → Cache-only mode (eventual consistency)
- High load → Throttle new connections, prioritize existing

**Retry Strategy**:
```go
// Exponential backoff
retries: 3
baseDelay: 100ms
maxDelay: 2s
backoff: baseDelay * 2^attempt
```

### 10.4 Data Consistency

**Consistency Model**: **Eventual Consistency** with **Strong Consistency** for scores

**Guarantees**:
- Scores: Strong consistency via atomic Redis operations
- Leaderboard: Eventual consistency (100ms delay acceptable)
- Session state: Eventual consistency across instances

**Conflict Resolution**:
- Last-write-wins for session metadata
- Atomic operations for scores (INCRBY)
- Optimistic locking for critical updates

---

## 11. Monitoring & Observability

### 11.1 Metrics (Prometheus)

**System Metrics**:
```
# Connections
websocket_active_connections{instance="server-1"}
websocket_total_connections{instance="server-1"}
websocket_connection_duration_seconds

# Sessions
quiz_active_sessions
quiz_total_participants
quiz_session_duration_seconds

# Performance
http_request_duration_seconds{endpoint="/ws"}
scoring_latency_seconds
leaderboard_update_latency_seconds

# Errors
error_total{type="client_error|server_error"}
connection_errors_total
database_errors_total

# Resources
go_goroutines
go_memstats_alloc_bytes
redis_connected_clients
postgresql_active_connections
```

**Business Metrics**:
```
quiz_answers_submitted_total
quiz_correct_answers_total
quiz_participants_joined_total
quiz_sessions_completed_total
```

### 11.2 Logging (Structured)

**Log Levels**:
- DEBUG: Detailed flow (disabled in production)
- INFO: Normal operations (user joined, answer submitted)
- WARN: Recoverable errors (invalid input, retries)
- ERROR: Serious errors (DB failure, unhandled exceptions)

**Log Format** (JSON):
```json
{
  "timestamp": "2025-11-16T10:30:00Z",
  "level": "INFO",
  "message": "User joined session",
  "user_id": "user-123",
  "session_id": "quiz-456",
  "trace_id": "abc-def-ghi",
  "latency_ms": 45
}
```

**Correlation**:
- Trace ID propagated through request chain
- User ID and Session ID in all relevant logs
- Request ID for debugging

### 11.3 Tracing (OpenTelemetry)

**Instrumentation Points**:
- WebSocket message handling (end-to-end)
- Database queries
- Redis operations
- Inter-service calls (Pub/Sub)

**Trace Example**:
```
Span 1: HandleWebSocketMessage (50ms)
  Span 2: ValidateSession (5ms)
  Span 3: ScoreEngine.SubmitAnswer (30ms)
    Span 4: Redis.INCRBY (2ms)
    Span 5: Database.InsertAnswer (20ms)
  Span 6: LeaderboardService.Update (10ms)
    Span 7: Redis.ZADD (2ms)
  Span 8: BroadcastUpdate (5ms)
```

### 11.4 Health Checks

**Liveness Probe**:
```
GET /health/live
Response: 200 if server is running
```

**Readiness Probe**:
```
GET /health/ready
Response: 200 if ready to accept traffic
Checks:
- Redis connection
- Database connection
- Memory usage < 90%
```

**Health Check Response**:
```json
{
  "status": "healthy",
  "checks": {
    "redis": {"status": "up", "latency_ms": 2},
    "database": {"status": "up", "latency_ms": 5},
    "memory": {"status": "ok", "usage_percent": 65}
  }
}
```

### 11.5 Alerting

**Critical Alerts** (PagerDuty):
- Error rate >1% for 5 minutes
- P99 latency >500ms for 5 minutes
- Database connection pool exhausted
- Redis unavailable

**Warning Alerts** (Slack):
- Error rate >0.5% for 10 minutes
- Memory usage >80%
- Connection count >8000 per instance
- Slow query detected (>1s)

---

## 12. Security Considerations

### 12.1 Input Validation

**WebSocket Messages**:
- JSON schema validation
- Maximum message size: 10KB
- Rate limiting: 100 messages/second per user
- Sanitize user inputs (username, answers)

**SQL Injection Prevention**:
- Parameterized queries only
- No dynamic SQL construction
- ORM with prepared statements

### 12.2 Authentication (Simplified for Challenge)

**Current Approach** (Mocked):
- User ID passed as query parameter
- No real authentication
- Session tokens generated server-side

**Production Recommendations**:
- JWT tokens for authentication
- OAuth 2.0 / OpenID Connect
- Secure WebSocket (WSS) only
- CORS configuration

### 12.3 Rate Limiting

**Per-User Limits**:
- WebSocket messages: 100/second
- Answer submissions: 10/second (prevent spam)
- Session joins: 5/minute

**Per-Session Limits**:
- Maximum participants: 10,000
- Maximum duration: 2 hours
- Auto-cleanup after expiry

**Implementation**:
```go
// Token bucket algorithm in Redis
key: rate_limit:{user_id}
tokens: 100
refill_rate: 100/second
```

### 12.4 Data Privacy

**Personal Data**:
- Minimal data collection (user_id, username)
- No sensitive information stored
- Session data TTL (auto-delete after 24 hours)

**Encryption**:
- TLS/SSL for all connections (WSS)
- At-rest encryption for database (production)

---

## 13. Implementation Plan

### 13.1 Phase 1: Foundation (MVP)

**Goal**: Basic real-time quiz server with core functionality

**Tasks**:
1. Project setup (Go modules, directory structure)
2. WebSocket server implementation
3. Basic message handling (JOIN, SUBMIT_ANSWER)
4. In-memory session management
5. Simple scoring engine
6. Basic leaderboard (in-memory)
7. Mock client for testing

**Deliverable**: Working server handling 100 concurrent users

**Timeline**: 2-3 days

### 13.2 Phase 2: Persistence & Scaling

**Goal**: Add Redis/PostgreSQL, support multiple instances

**Tasks**:
1. Redis integration (sessions, leaderboard)
2. PostgreSQL schema and integration
3. Pub/Sub for cross-instance messaging
4. Connection manager refactoring
5. Database repositories
6. Atomic score updates

**Deliverable**: Scalable server with persistent state

**Timeline**: 2-3 days

### 13.3 Phase 3: Observability & Reliability

**Goal**: Production-ready monitoring and error handling

**Tasks**:
1. Prometheus metrics integration
2. Structured logging (Zap)
3. Health check endpoints
4. Error handling and recovery
5. Circuit breakers
6. Graceful shutdown

**Deliverable**: Observable, resilient server

**Timeline**: 1-2 days

### 13.4 Phase 4: Testing & Documentation

**Goal**: Comprehensive testing and documentation

**Tasks**:
1. Unit tests (>80% coverage)
2. Integration tests (Redis, PostgreSQL)
3. Load testing (k6 scripts)
4. API documentation
5. Deployment guide (Docker Compose)
6. Performance benchmarking

**Deliverable**: Fully tested and documented system

**Timeline**: 2-3 days

### 13.5 AI Collaboration Strategy

**AI Tool Usage**:

1. **GitHub Copilot** (Primary):
   - Code generation for boilerplate (struct definitions, interfaces)
   - Test case generation
   - Documentation comments

2. **Claude AI** (Secondary):
   - Architecture review and feedback
   - Algorithm optimization suggestions
   - Error handling patterns

3. **ChatGPT** (Tertiary):
   - Debugging assistance
   - Performance optimization ideas
   - Documentation review

**Verification Process**:
- All AI-generated code reviewed line-by-line
- Unit tests for all generated functions
- Integration tests for critical paths
- Manual testing for WebSocket flows
- Code linting and static analysis
- Performance profiling for hot paths

**Documentation**:
- Code comments marking AI-assisted sections
- Separate AI_COLLABORATION.md file
- Prompts and responses logged
- Verification steps documented

---

## Decision Records

### Decision 1 - November 16, 2025
**Decision**: Implement server component (not client)
**Context**: Challenge requires implementing one core component
**Options**: 
  - Server: More complex, demonstrates concurrency, scalability
  - Client: Simpler, UI-focused, less engineering depth
**Rationale**: Server showcases backend engineering skills better, handles real-time complexity, and is more aligned with system design requirements
**Impact**: Focus development on Go server, mock clients for testing
**Review**: N/A (core design decision)

### Decision 2 - November 16, 2025
**Decision**: Use Go (Golang) for server implementation
**Context**: Need high-performance language for real-time WebSocket handling
**Options**:
  - Go: Great concurrency, performance, simple deployment
  - Node.js: Good for WebSockets, but less performant
  - Java/Spring: Enterprise-grade, but more complex
**Rationale**: Go's goroutines and channels are ideal for concurrent WebSocket connections; compiled binary simplifies deployment; strong real-time system track record
**Impact**: Use gorilla/websocket, gin framework, native concurrency
**Review**: After load testing (if performance issues arise)

### Decision 3 - November 16, 2025
**Decision**: Use Redis for state management and leaderboard
**Context**: Need fast, scalable state storage for real-time updates
**Options**:
  - Redis: In-memory, sorted sets for leaderboard, pub/sub
  - PostgreSQL only: Simpler, but slower for real-time
  - In-memory only: Fast, but not scalable
**Rationale**: Redis sorted sets (ZADD, ZRANGE) are perfect for leaderboards; pub/sub enables cross-instance messaging; atomic operations ensure score consistency
**Impact**: Add Redis dependency, implement caching layer
**Review**: If scale exceeds Redis capacity (~50K ops/sec)

### Decision 4 - November 16, 2025
**Decision**: Batch leaderboard updates (100ms window)
**Context**: Frequent score updates could overwhelm clients with messages
**Options**:
  - Real-time (every score change): Most responsive, but high traffic
  - Batched (100ms): Balanced, reduces traffic 10-100x
  - Polling (1s): Lowest traffic, but noticeable lag
**Rationale**: 100ms delay is imperceptible to users; dramatically reduces message volume; allows aggregating multiple score changes
**Impact**: Implement batching logic in leaderboard service
**Review**: Adjust batch window based on user testing

### Decision 5 - November 16, 2025
**Decision**: Eventual consistency for leaderboard, strong consistency for scores
**Context**: Need to balance consistency with performance
**Options**:
  - Strong consistency everywhere: Accurate, but slow
  - Eventual everywhere: Fast, but confusing for users
  - Hybrid: Score strong, leaderboard eventual
**Rationale**: Users care most about their own score (must be accurate); leaderboard ranking delays of <200ms are acceptable; allows performance optimization
**Impact**: Use atomic Redis operations for scores, accept propagation delay for rankings
**Review**: Monitor user feedback on ranking accuracy

---

## Next Steps

1. ✅ Requirements analysis complete (`requirements.md`)
2. ✅ System design complete (`design.md`)
3. ⏭️ Create detailed implementation tasks (`tasks.md`)
4. ⏭️ Begin Phase 1 implementation
5. ⏭️ Set up development environment (Go, Redis, PostgreSQL)
6. ⏭️ Implement WebSocket server foundation

---

**Document Version**: 1.0  
**Authors**: AI-Assisted Design (Claude AI + Human Review)  
**Status**: Ready for Implementation

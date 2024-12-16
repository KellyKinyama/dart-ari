CREATE TABLE queues (
    name VARCHAR(128) PRIMARY KEY,      -- Name of the queue
    musiconhold VARCHAR(128),          -- Music on hold class
    strategy VARCHAR(32),              -- Call distribution strategy (e.g., ringall, leastrecent)
    timeout INT DEFAULT 15,            -- Ring timeout in seconds
    retry INT DEFAULT 5,               -- Retry time in seconds
    wrapuptime INT DEFAULT 0,          -- Wrap-up time between calls
    maxlen INT DEFAULT 0,              -- Maximum number of callers in the queue
    servicelevel INT DEFAULT 0,        -- SLA in seconds
    weight INT DEFAULT 0,              -- Queue weight for prioritization
    timeoutpriority VARCHAR(32),       -- Timeout priority (optional)
    autopause CHAR(1) DEFAULT 'N',     -- Auto-pause members (Y/N)
    autopausebusy CHAR(1) DEFAULT 'N', -- Auto-pause members on busy (Y/N)
    autopauseunavail CHAR(1) DEFAULT 'N', -- Auto-pause members on unavailable (Y/N)
    joinempty CHAR(1) DEFAULT 'Y',     -- Allow callers to join if no members (Y/N)
    leavewhenempty CHAR(1) DEFAULT 'N', -- Leave when queue is empty (Y/N)
    eventmemberstatus CHAR(1) DEFAULT 'N', -- Send member status events (Y/N)
    eventwhencalled CHAR(1) DEFAULT 'N',   -- Send event when call is made (Y/N)
    reportholdtime CHAR(1) DEFAULT 'N', -- Report hold time to members (Y/N)
    announceholdtime CHAR(1) DEFAULT 'N', -- Announce hold time to caller (Y/N)
    announcefrequency INT DEFAULT 0,   -- Frequency of announcements (seconds)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE queue_members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    queue_name VARCHAR(128) NOT NULL,  -- Queue this member belongs to
    interface VARCHAR(128) NOT NULL,  -- Interface (e.g., SIP/1001, Local/1002@context)
    membername VARCHAR(128),          -- Descriptive name of the member
    penalty INT DEFAULT 0,            -- Priority level of the member
    paused CHAR(1) DEFAULT 'N',       -- Whether the member is paused (Y/N)
    uniqueid VARCHAR(128),            -- Unique identifier for dynamic members
    state_interface VARCHAR(128),     -- Interface for device state tracking (optional)
    wrapuptime INT DEFAULT 0,         -- Member-specific wrap-up time
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (queue_name) REFERENCES queues(name) ON DELETE CASCADE
);

CREATE TABLE queue_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Event timestamp
    callid VARCHAR(128),                      -- Unique call identifier
    queue_name VARCHAR(128),                  -- Queue name
    agent VARCHAR(128),                       -- Agent involved (if applicable)
    event VARCHAR(128),                       -- Event type (e.g., ENTERQUEUE, CONNECT, COMPLETEAGENT)
    data1 VARCHAR(255) DEFAULT NULL,          -- Additional data (e.g., caller ID)
    data2 VARCHAR(255) DEFAULT NULL,
    data3 VARCHAR(255) DEFAULT NULL,
    data4 VARCHAR(255) DEFAULT NULL,
    data5 VARCHAR(255) DEFAULT NULL,
    FOREIGN KEY (queue_name) REFERENCES queues(name) ON DELETE SET NULL
);


-- To create a new queue named "support" in the queues table:
INSERT INTO queues (
    name, musiconhold, strategy, timeout, retry, wrapuptime, maxlen, servicelevel,
    weight, timeoutpriority, autopause, autopausebusy, autopauseunavail,
    joinempty, leavewhenempty, eventmemberstatus, eventwhencalled,
    reportholdtime, announceholdtime, announcefrequency
) VALUES (
    'inbound', 'default', 'longest_waiting', 30, 5, 0, 0, 20,
    0, 'ringall', 'N', 'N', 'N',
    'Y', 'N', 'N', 'N',
    'N', 'N', 30
);

-- Alternatively, if the member is not already listed in the queue_members table:
INSERT INTO queue_members (queue_name, interface, paused) 
VALUES ('inbound', 'PJSIP/6003', 'N');

/*Check if a member is logged in*/
SELECT * 
FROM queue_members 
WHERE queue_name = 'inbound' AND interface = 'PJSIP/6003' AND paused = 'N';

/*SQL Query to Log In a Member:*/
UPDATE queue_members
SET paused = 'N'
WHERE queue_name = 'inbound' AND interface = 'PJSIP/6003';


-- SQL Query to Log Out a Member:
UPDATE queue_members
SET paused = 'Y'
WHERE queue_name = 'inbound' AND interface = 'PJSIP/6003';
# SQLite Schema V1

Use GRDB migrations.  Do not generate tables from Swift structs automatically.

Store UUID values as uppercase UUID strings.  Store dates as ISO 8601 strings.  Store arrays, metadata, refs, and time values as JSON text.

## projects

```sql
CREATE TABLE projects (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    app_context TEXT,
    schema_version INTEGER NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
```

## objects

```sql
CREATE TABLE objects (
    id TEXT PRIMARY KEY NOT NULL,
    project_id TEXT NOT NULL,
    name TEXT NOT NULL,
    object_type TEXT NOT NULL,
    summary TEXT,
    aliases_json TEXT NOT NULL,
    metadata_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    FOREIGN KEY(project_id) REFERENCES projects(id)
);

CREATE INDEX idx_objects_project_type ON objects(project_id, object_type);
CREATE INDEX idx_objects_project_name ON objects(project_id, name);
CREATE INDEX idx_objects_project_archived ON objects(project_id, archived_at);
```

## events

```sql
CREATE TABLE events (
    id TEXT PRIMARY KEY NOT NULL,
    project_id TEXT NOT NULL,
    title TEXT NOT NULL,
    summary TEXT,
    time_json TEXT NOT NULL,
    time_sort_key REAL,
    time_confidence REAL NOT NULL,
    metadata_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    FOREIGN KEY(project_id) REFERENCES projects(id)
);

CREATE INDEX idx_events_project_sort_key ON events(project_id, time_sort_key);
CREATE INDEX idx_events_project_title ON events(project_id, title);
CREATE INDEX idx_events_project_archived ON events(project_id, archived_at);
```

## claims

```sql
CREATE TABLE claims (
    id TEXT PRIMARY KEY NOT NULL,
    project_id TEXT NOT NULL,
    statement TEXT NOT NULL,
    claim_type TEXT NOT NULL,
    status TEXT NOT NULL,
    confidence REAL NOT NULL,
    source_ids_json TEXT NOT NULL,
    metadata_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    FOREIGN KEY(project_id) REFERENCES projects(id)
);

CREATE INDEX idx_claims_project_status ON claims(project_id, status);
CREATE INDEX idx_claims_project_type ON claims(project_id, claim_type);
CREATE INDEX idx_claims_project_archived ON claims(project_id, archived_at);
```

## sources

```sql
CREATE TABLE sources (
    id TEXT PRIMARY KEY NOT NULL,
    project_id TEXT NOT NULL,
    title TEXT NOT NULL,
    source_type TEXT NOT NULL,
    original_filename TEXT,
    stored_path TEXT,
    checksum TEXT,
    origin TEXT,
    citation TEXT,
    extracted_text_path TEXT,
    metadata_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    FOREIGN KEY(project_id) REFERENCES projects(id)
);

CREATE INDEX idx_sources_project_type ON sources(project_id, source_type);
CREATE INDEX idx_sources_project_checksum ON sources(project_id, checksum);
CREATE INDEX idx_sources_project_archived ON sources(project_id, archived_at);
```

## notes

```sql
CREATE TABLE notes (
    id TEXT PRIMARY KEY NOT NULL,
    project_id TEXT NOT NULL,
    title TEXT,
    body TEXT NOT NULL,
    linked_refs_json TEXT NOT NULL,
    source_ids_json TEXT NOT NULL,
    metadata_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    FOREIGN KEY(project_id) REFERENCES projects(id)
);

CREATE INDEX idx_notes_project_archived ON notes(project_id, archived_at);
```

## links

```sql
CREATE TABLE links (
    id TEXT PRIMARY KEY NOT NULL,
    project_id TEXT NOT NULL,
    from_kind TEXT NOT NULL,
    from_id TEXT NOT NULL,
    relationship_type TEXT NOT NULL,
    to_kind TEXT NOT NULL,
    to_id TEXT NOT NULL,
    time_json TEXT,
    time_sort_key REAL,
    time_confidence REAL,
    confidence REAL NOT NULL,
    summary TEXT,
    source_ids_json TEXT NOT NULL,
    metadata_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    FOREIGN KEY(project_id) REFERENCES projects(id)
);

CREATE INDEX idx_links_from ON links(project_id, from_kind, from_id);
CREATE INDEX idx_links_to ON links(project_id, to_kind, to_id);
CREATE INDEX idx_links_relationship ON links(project_id, relationship_type);
CREATE INDEX idx_links_project_sort_key ON links(project_id, time_sort_key);
CREATE INDEX idx_links_project_archived ON links(project_id, archived_at);
```

## proposals

```sql
CREATE TABLE proposals (
    id TEXT PRIMARY KEY NOT NULL,
    project_id TEXT NOT NULL,
    summary TEXT NOT NULL,
    detail TEXT,
    status TEXT NOT NULL,
    source_ids_json TEXT NOT NULL,
    confidence REAL NOT NULL,
    created_by TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    reviewed_at TEXT,
    FOREIGN KEY(project_id) REFERENCES projects(id)
);

CREATE INDEX idx_proposals_project_status ON proposals(project_id, status);
CREATE INDEX idx_proposals_project_created ON proposals(project_id, created_at);
```

## proposal_operations

```sql
CREATE TABLE proposal_operations (
    id TEXT PRIMARY KEY NOT NULL,
    project_id TEXT NOT NULL,
    proposal_id TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    kind TEXT NOT NULL,
    target_kind TEXT,
    target_id TEXT,
    summary TEXT,
    payload_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY(project_id) REFERENCES projects(id),
    FOREIGN KEY(proposal_id) REFERENCES proposals(id)
);

CREATE INDEX idx_proposal_operations_proposal ON proposal_operations(project_id, proposal_id, sort_order);
CREATE INDEX idx_proposal_operations_kind ON proposal_operations(project_id, kind);
```

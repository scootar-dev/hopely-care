# Support Circle API

Base `/api`, authenticated Sanctum token, existing `{success,message,data}` envelope. Patient, Caregiver, and Admin accounts may use communities. Posting is explicit sharing, independent of private-health processing. API limit 120/min/user; community mutations additionally 20/min/user. IDs use UUID primary keys.

| Method | Path | Body/result |
|---|---|---|
| GET | `/communities` | `search` ≤100, category cancer/treatment/emotional/survivor/caregiver, sort relevant/newest/active, page → community page |
| GET | `/communities/{community}` | `{community,guidelines}`; active community, excludes banned requester |
| POST | `/communities/{community}/join` | `{display_name: string(2..60), rules_accepted:true}`; name becomes public community alias; role always server-owned |
| DELETE | `/communities/{community}/leave` | Own membership becomes left; moderator role relinquished; banned state preserved |
| GET | `/communities/{community}/posts` | Visible story page; `page`, optional `mine=1` |
| POST | `/communities/{community}/posts` | JSON `{content: string(2..4000), sharing_acknowledged:true}`; or multipart with those fields plus image. Returns story and moderation_status, HTTP 201 |
| GET | `/community/posts/{post}` | Visible story, author alias, counts, my_reaction, revision, permissions |
| PUT | `/community/posts/{post}` | Own content, sharing_acknowledged:true, required revision; re-moderates; no image replacement on edit |
| DELETE | `/community/posts/{post}` | Own story soft delete; removes associated image file |
| GET | `/community/posts/{post}/image` | Authenticated `{mime_type,base64}`, private/no-store. Optional `review=1` requires scoped moderator authorization |
| POST | `/community/posts/{post}/reactions` | `{reaction_type: support/encouragement/thanks}`; one reaction per member/post; returns updated story |
| DELETE | `/community/posts/{post}/reactions` | Removes requester's reaction |
| GET | `/community/posts/{post}/comments` | Visible comment page, 30/page |
| POST | `/community/posts/{post}/comments` | `{content: string(2..4000), sharing_acknowledged:true}`; member and approved parent; returns comment, HTTP 201 |
| DELETE | `/community/comments/{comment}` | Own comment soft delete |
| POST | `/community/reports` | `{reportable_type: post/comment, reportable_id:uuid, reason, description?:string≤1000}`; allowed reasons misinformation/harassment/spam/privacy/unsafe/other; duplicates idempotent |
| POST | `/users/{user}/block` | Blocks community visibility/interactions both ways; cannot target self |
| DELETE | `/users/{user}/block` | Unblocks requester's block |
| GET | `/community/my-communities` | Membership page: active/pending/banned |
| GET | `/community/home` | `{recommended:[{community,reason}],recommendation_method,joined,recent}`; limited previews; full paginated endpoints above |
| GET | `/community/feed` | Visible community story page; `page`, optional `mine=1`; own held/removed stories remain manageable |
| GET/PUT | `/community/preferences` | Own display_name, notifications_enabled, recommendation_enabled; interests {cancer_type?,treatment_phase?,support_preferences?}; turning recommendation off deletes interests |
| GET | `/community/safety` | guidelines, own report page (20/page), own blocked aliases, can_moderate |
| GET | `/community/moderation` | `kind=post/comment/report`, page → scoped pending/flagged content or unresolved reports; 20/page |
| POST | `/community/moderation/{kind}/{id}` | Content actions approve/remove; report actions remove/dismiss; required note(3..500), revision required for changes to existing content. 409 if stale, 403 for own approval/unscoped moderator |

Community, membership and story pages use 20/page and `{items,page,last_page,total}`. Report/queue pages use `{items,page,last_page}`. Community IDs, counts and aliases are real database data; private profile fields, account names/emails and image paths are omitted.

Story authors may remove their own submissions after leaving or membership restriction. Only approved stories are public to other signed-in users; pending/flagged/removed submissions are visible to their author and to authorized review paths. Authors also receive `moderation_source` (model/rules/manual_review/unavailable/human/synthetic_seed) for their own stories; raw reviewer notes are not returned. Blocks filter story authors, comments, reaction counts and subsequent interaction notifications. Medical data never enters these payloads automatically.

## Internal FastAPI

Both routes require `X-Internal-Service-Key` and reject unrecognized fields. The mobile app never calls them directly.

`POST /v1/ai/community/moderate`:

```json
{"content_type":"post","content":"Terima kasih sudah menemani hari ini."}
```

Response: `{status:safe|review|unsafe,categories:[],confidence:0..1,reason:string,mode:model|rules|manual_review}`. Mock mode routes submissions to manual review. Tripwires route potential medical claims/harassment/scams to review, with no claimed model confidence. Live structured decisions below 0.8 or with inconsistent safe/category results also require review. Laravel stores pending on provider failure and holds images for human review.

`POST /v1/ai/community/recommend`:

```json
{
  "personalization_allowed": true,
  "patient_context": {"cancer_type":"kanker payudara","treatment_phase":"kemoterapi","support_preferences":["dukungan emosional"]},
  "communities": [{"id":"catalogue-uuid","name":"Ruang Dukungan Emosional","category":"emotional","cancer_type":null,"treatment_phase":null,"support_type":"dukungan emosional","activity_count":2}]
}
```

Returns `{recommendations:[{community_id,score,reason}],method:metadata}`. At most six unique catalogue IDs. No journal/chat input is accepted. When personalization is false, interests are ignored. Ranking is deterministic metadata matching; scores are relevance weights, not clinical probability or LLM inference. Laravel falls back to the active catalogue if matching is unavailable and verifies returned IDs.

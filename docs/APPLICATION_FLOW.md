# Application flow
```mermaid
flowchart TD
 W["Welcome"] --> R["Patient or caregiver"]
 R --> A["Register / login"]
 A --> C["Privacy and consent"]
 C --> H["Patient home"]
 C --> G["Caregiver dashboard"]
 H --> D["Check-in / symptoms / treatment"]
 H --> J["Private journal"]
 J --> X{"Analysis permitted?"}
 X -->|"Yes: global + entry"| E["Emotion signal"]
 X -->|No| S["Store privately"]
 D --> T["Longitudinal insights"]
 E --> T
 T --> B["Contextual companion / activities"]
 H --> P["Care circle permissions"]
 P --> G
 G --> K["Filtered caregiver coach"]
 T --> V["Doctor summary preview"]
 V --> F["Explicit PDF export"]
```
Home → Perjalanan → Hopely AI → Wawasan → Profil follows Stitch. Check-in and summary use dedicated routes. Journal, symptoms, activities and trusted knowledge are reachable from the home/profile/journey screens. All data screens include progress, empty and retry states. Form errors preserve input. No offline queue silently uploads private text later.

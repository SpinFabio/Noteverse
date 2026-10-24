# Graph view settings persistence

`GraphViewSettingsStore` is the persistence boundary for graph viewport
preferences. Its current implementation uses Flutter's cross-platform
`shared_preferences` API and stores one versioned JSON value under the
`graph_view_settings` key.

The platform chooses the physical storage mechanism. Web builds use browser
storage, while native builds use their platform preference store. These
preferences are local to one browser or device and are not synchronized.

Keep consumers dependent on `GraphViewSettingsStore`, not on platform storage
APIs. This allows a future backend-synchronized implementation to replace the
local store without changing graph-view widgets.

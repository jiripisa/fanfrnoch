// FanfrnochAUExports - no code. This target exists for its linker setting in Package.swift: the
// Audio Unit's dynamic library exports only its factory function, because a plug-in shares the
// host's process with other plug-ins. The setting sits here, and not on the Audio Unit's own
// target, so that the tests can link that target without it.

typedef int FanfrnochAUExportsHasNoCode;

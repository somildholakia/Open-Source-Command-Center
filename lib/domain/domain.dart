/// Domain layer: normalized entities, the provider capability interface, and
/// typed provider failures. UI and feature layers depend only on this barrel;
/// provider implementations (GitHub, future GitLab/Bitbucket/...) plug in
/// behind `DeveloperProvider`.
library;

export 'entities/entities.dart';
export 'errors/errors.dart';
export 'intelligence/intelligence.dart';
export 'providers/providers.dart';

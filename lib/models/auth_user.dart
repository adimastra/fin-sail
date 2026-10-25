class AuthUser {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String provider;
  final bool isGuest;

  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.provider = 'google',
    this.isGuest = false,
  });

  factory AuthUser.fromSupabaseUser(dynamic user) {
    final metadata = user.userMetadata ?? {};
    final fullName = metadata['full_name']?.toString() ??
        metadata['name']?.toString() ??
        user.email?.split('@').first ??
        'Voyager';
    final avatar = metadata['avatar_url']?.toString() ??
        metadata['picture']?.toString();

    return AuthUser(
      id: user.id as String,
      email: (user.email ?? 'user@gmail.com') as String,
      displayName: fullName,
      avatarUrl: avatar,
      provider: 'google',
      isGuest: false,
    );
  }

  factory AuthUser.guest({
    String email = 'alex.guest@finsail.demo',
    String displayName = 'Alex Morgan',
  }) {
    return AuthUser(
      id: 'demo-guest-user',
      email: email,
      displayName: displayName,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
      provider: 'guest',
      isGuest: true,
    );
  }

  factory AuthUser.mockGoogleUser({
    String email = 'alex.sail@gmail.com',
    String displayName = 'Alex Morgan',
  }) {
    return AuthUser(
      id: 'demo-google-user',
      email: email,
      displayName: displayName,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
      provider: 'google',
      isGuest: false,
    );
  }
}

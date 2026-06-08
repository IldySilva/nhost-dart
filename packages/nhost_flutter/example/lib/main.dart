// nhost_flutter example app.
// Demonstrates every P1 Flutter Experience API:
//   Nhost.initialize(), NhostAuthGate, NhostAuthStateBuilder,
//   NhostSignedIn/Out, NhostUserBuilder, authStateChanges, authStateListenable
//   sign-in, register, anonymous sign-in, forgot password, change password,
//   storage upload (uploadBytes) and publicUrl
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nhost_flutter/nhost_flutter.dart';

import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Nhost.initialize(
    subdomain: Subdomain(subdomain: subdomain, region: region),
    // SecureAuthStore is used by default — tokens are persisted automatically.
    // For local development, swap the line above with:
    //   await Nhost.local();
  );

  runApp(const NhostExampleApp());
}

class NhostExampleApp extends StatelessWidget {
  const NhostExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NhostAuthProvider(
      auth: Nhost.instance.auth,
      child: MaterialApp(
        title: 'nhost_flutter example',
        home: NhostAuthGate(
          loading: (_) => const _SplashScreen(),
          signedOut: (_) => const _SignInScreen(),
          signedIn: (_, user, __) => _HomeScreen(user: user),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Splash
// ---------------------------------------------------------------------------

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign-in
// ---------------------------------------------------------------------------

class _SignInScreen extends StatefulWidget {
  const _SignInScreen();

  @override
  State<_SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<_SignInScreen> {
  final _email = TextEditingController(text: 'user-1@nhost.io');
  final _password = TextEditingController(text: 'password-1');
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.signInEmailPassword(
        email: _email.text,
        password: _password.text,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.signInAnonymous(null, null, null);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anonymous sign in failed: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToRegister() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const _RegisterScreen()),
      );

  void _goToForgotPassword() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const _ForgotPasswordScreen()),
      );

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _goToForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _signIn,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('Continue as guest'),
                onPressed: _loading ? null : _signInAnonymously,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _goToRegister,
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

class _RegisterScreen extends StatefulWidget {
  const _RegisterScreen();

  @override
  State<_RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<_RegisterScreen> {
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.signUp(
        email: _email.text,
        password: _password.text,
        displayName: _displayName.text.isEmpty ? null : _displayName.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Check your email to verify.'),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _displayName,
              decoration: const InputDecoration(
                labelText: 'Display name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create account'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Forgot password — Step 1: request reset email
// ---------------------------------------------------------------------------

class _ForgotPasswordScreen extends StatefulWidget {
  const _ForgotPasswordScreen();

  @override
  State<_ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<_ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  // Deep-link scheme registered in AndroidManifest / Info.plist.
  // Replace with your own scheme. When the user taps the link in their email
  // on the same device, the app opens and the router extracts the ticket from
  // the URL automatically.
  static const _resetRedirectUrl = 'com.example.nhostapp://reset-password';

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.resetPassword(
        email: _email.text,
        // Passing redirectTo tells Nhost what URL to embed in the reset email.
        // If the user taps the link on the same device, the app opens and the
        // router can extract ?ticket=xxx and pre-fill the next screen.
        // If the deep link doesn't fire, the user types the code manually.
        redirectTo: _resetRedirectUrl,
      );
      if (!mounted) return;
      setState(() => _sent = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_read_outlined,
                      size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    'Reset email sent to ${_email.text}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the link in the email — the app will open and fill the code automatically.\n\nOn a different device, or the link didn\'t open? Tap below to type the code manually.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // go_router / uni_links: handle the incoming deep link and
                  // navigate to _SetNewPasswordScreen(ticket: extractedTicket).
                  // This button is the manual fallback.
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const _SetNewPasswordScreen(ticket: ''),
                      ),
                    ),
                    child: const Text('Enter code manually'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to sign in'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Enter your email and we'll send you a password reset link.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _send,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send reset email'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Forgot password — Step 2: enter the reset code and set new password.
//
// Two entry paths, same screen:
//
//  A) Deep link (best case):
//     resetPassword(redirectTo: 'myapp://reset-password') embeds a link in the
//     email. User taps it → app opens → router extracts ?ticket=xxx from the
//     URL → navigate here with ticket pre-filled.
//
//  B) Manual fallback (different device / link didn't fire):
//     User opens the app, taps "Enter code manually", copies the code from
//     the email, types it here.
//
// Either way the final call is:
//   changePassword(newPassword: password, ticket: code) — no sign-in needed.
// ---------------------------------------------------------------------------

class _SetNewPasswordScreen extends StatefulWidget {
  const _SetNewPasswordScreen({required this.ticket});
  // Pre-filled when the app is opened via deep link and the ticket is parsed
  // from the URL automatically. Empty string for manual entry.
  final String ticket;

  @override
  State<_SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<_SetNewPasswordScreen> {
  late final TextEditingController _code;
  final _newPassword = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.ticket);
  }

  Future<void> _setPassword() async {
    if (_code.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the code from your email')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.changePassword(
        newPassword: _newPassword.text,
        ticket: _code.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated! You can now sign in.')),
      );
      Navigator.of(context)
        ..pop()
        ..pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid or expired code: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set new password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 48, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text(
              'Enter the reset code from your email and choose a new password.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Reset code',
                border: OutlineInputBorder(),
                helperText:
                    'Pre-filled if you opened the app via the email link, '
                    'or copy it manually from the email.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPassword,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _setPassword,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Set new password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home — demonstrates all P1 widgets
// ---------------------------------------------------------------------------

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final isAnonymous = user.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text('nhost_flutter demo'),
        actions: [
          if (isAnonymous)
            TextButton.icon(
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _ConvertAnonymousScreen(),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Change password',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const _ChangePasswordScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => Nhost.instance.auth.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isAnonymous)
            _InfoBanner(
              message:
                  'You are signed in as a guest. Upgrade your account to save your data.',
              action: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _ConvertAnonymousScreen(),
                  ),
                ),
                child: const Text('Upgrade now'),
              ),
            ),
          _Section(
            title: 'NhostUserBuilder',
            child: NhostUserBuilder(
              builder: (_, u) => Text(
                'Hello, ${u.displayName.isNotEmpty ? u.displayName : (u.email ?? 'guest')}!',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          _Section(
            title: 'NhostSignedIn / NhostSignedOut',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NhostSignedIn(
                  child: Chip(
                    avatar: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text('Signed in'),
                  ),
                ),
                NhostSignedOut(
                  child: Chip(
                    avatar: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Signed out'),
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'NhostAuthStateBuilder (sealed switch)',
            child: NhostAuthStateBuilder(
              builder: (_, state) => switch (state) {
                AuthStateLoading() => const Text('Loading…'),
                AuthStateSignedOut() => const Text('Not signed in'),
                AuthStateSignedIn(:final user) =>
                  Text('Signed in as ${user.email ?? 'guest'}'),
              },
            ),
          ),
          _Section(
            title: 'authStateChanges stream',
            child: StreamBuilder<AuthState>(
              stream: Nhost.instance.auth.authStateChanges,
              builder: (_, snap) {
                final state = snap.data;
                return Text(switch (state) {
                  null => 'Waiting for first event…',
                  AuthStateLoading() => 'Loading…',
                  AuthStateSignedOut() => 'Stream: signed out',
                  AuthStateSignedIn(:final user) =>
                    'Stream: signed in as ${user.email ?? 'guest'}',
                });
              },
            ),
          ),
          _Section(
            title: 'authStateListenable',
            child: ValueListenableBuilder<AuthState>(
              valueListenable: Nhost.instance.auth.authStateListenable,
              builder: (_, state, __) => Text(switch (state) {
                AuthStateLoading() => 'Listenable: loading…',
                AuthStateSignedOut() => 'Listenable: signed out',
                AuthStateSignedIn(:final user) =>
                  'Listenable: signed in as ${user.email ?? 'guest'}',
              }),
            ),
          ),
          _Section(
            title: 'Storage',
            child: FilledButton.icon(
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Open storage demo'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _StorageScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Storage demo — image_picker → uploadXFile → publicUrl → Image.network
// ---------------------------------------------------------------------------

class _StorageScreen extends StatefulWidget {
  const _StorageScreen();

  @override
  State<_StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<_StorageScreen> {
  final _picker = ImagePicker();

  // Uploaded files: list of {id, url, name}
  final List<_UploadedFile> _files = [];
  bool _uploading = false;
  double? _progress;
  String? _error;

  Future<void> _pickAndUpload(ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xFile == null) return;
    await _upload(xFile);
  }

  Future<void> _pickVideo() async {
    final xFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (xFile == null) return;
    await _upload(xFile);
  }

  Future<void> _upload(XFile xFile) async {
    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });

    try {
      // uploadXFile is the Flutter extension — takes XFile directly.
      // mime type is inferred from the file extension automatically.
      final meta = await Nhost.instance.storage.uploadXFile(
        xFile,
        onUploadProgress: (_, sent, total) {
          if (mounted) setState(() => _progress = sent / total);
        },
      );

      // publicUrl is a pure URL construction — no HTTP call.
      final url = Nhost.instance.storage.publicUrl(meta.id);

      setState(() {
        _files.insert(0, _UploadedFile(id: meta.id, url: url, name: xFile.name));
      });
    } on ApiException catch (e) {
      setState(() => _error = 'Upload failed: ${e.responseBody}');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(_UploadedFile file) async {
    try {
      await Nhost.instance.storage.delete(file.id);
      setState(() => _files.remove(file));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${e.responseBody}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storage demo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                        onPressed: _uploading
                            ? null
                            : () => _pickAndUpload(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                        onPressed: _uploading
                            ? null
                            : () => _pickAndUpload(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.video_library_outlined),
                        label: const Text('Video'),
                        onPressed: _uploading ? null : _pickVideo,
                      ),
                    ),
                  ],
                ),
                if (_uploading) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 4),
                  Text(
                    'Uploading… ${((_progress ?? 0) * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          if (_files.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No uploads yet.\nPick a photo, take one with the camera,\nor pick a video to upload.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _files.length,
                itemBuilder: (_, i) => _FileCard(
                  file: _files[i],
                  onDelete: () => _delete(_files[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UploadedFile {
  const _UploadedFile({required this.id, required this.url, required this.name});
  final String id;
  final String url;
  final String name;
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.file, required this.onDelete});
  final _UploadedFile file;
  final VoidCallback onDelete;

  bool get _isImage {
    final ext = file.name.split('.').last.toLowerCase();
    return {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isImage)
            // publicUrl result fed directly into Image.network
            Image.network(
              file.url,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    ),
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 80,
                child: Center(
                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            )
          else
            const SizedBox(
              height: 80,
              child: Center(
                child: Icon(Icons.insert_drive_file_outlined,
                    size: 40, color: Colors.grey),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        file.id,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Convert anonymous account → full account
// ---------------------------------------------------------------------------

class _ConvertAnonymousScreen extends StatefulWidget {
  const _ConvertAnonymousScreen();

  @override
  State<_ConvertAnonymousScreen> createState() =>
      _ConvertAnonymousScreenState();
}

class _ConvertAnonymousScreenState extends State<_ConvertAnonymousScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _convert() async {
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.deanonymizeUser(
        DeanonymizeOptions(
          signInMethod: DeanonymizeSignInMethod.emailPassword,
          email: _email.text,
          password: _password.text,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account upgraded! Check your email.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upgrade failed: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Convert your guest account to a permanent account.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _convert,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Upgrade account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Change password (for logged-in users)
// ---------------------------------------------------------------------------

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _newPassword = TextEditingController();
  bool _loading = false;

  Future<void> _changePassword() async {
    setState(() => _loading = true);
    try {
      await Nhost.instance.auth.changePassword(
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.responseBody}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _newPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _newPassword,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _changePassword,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, required this.action});
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          action,
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import '../../core/utils/validators.dart';
import 'base_viewmodel.dart';

class AuthViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  AuthViewModel(this._userRepository) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _userRepository.authStateChanges.listen((user) {
      if (user == null) {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    setState(ViewState.busy);

    try {
      final user = await _userRepository.signInWithEmail(email, password);
      if (user != null) {
        _currentUser = user;
        setState(ViewState.idle);
        return true;
      } else {
        setError('Login failed');
        return false;
      }
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String displayName,
  ) async {
    setState(ViewState.busy);

    try {
      final user = await _userRepository.registerWithEmail(
        email,
        password,
        displayName,
      );
      if (user != null) {
        _currentUser = user;
        setState(ViewState.idle);
        return true;
      } else {
        setError('Registration failed');
        return false;
      }
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    setState(ViewState.busy);

    try {
      await _userRepository.signOut();
      _currentUser = null;
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<bool> resetPassword(String email) async {
    setState(ViewState.busy);

    try {
      await _userRepository.resetPassword(email);
      setState(ViewState.idle);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  // Form validation
  String? validateEmail(String? email) => Validators.validateEmail(email);
  String? validatePassword(String? password) =>
      Validators.validatePassword(password);
  String? validateDisplayName(String? name) =>
      Validators.validateDisplayName(name);
}

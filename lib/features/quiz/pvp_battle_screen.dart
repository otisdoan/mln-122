import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../models/quiz_question.dart';
import '../../services/auth_service.dart';
import '../../services/pvp_service.dart';
import '../../widgets/quiz_option_button.dart';

class PvpBattleScreen extends StatefulWidget {
  final String? roomId; // non-null when joining from notification

  const PvpBattleScreen({super.key, this.roomId});

  @override
  State<PvpBattleScreen> createState() => _PvpBattleScreenState();
}

enum PvpPhase { lobby, waiting, accepted, countdown, playing, finished }

class _PvpBattleScreenState extends State<PvpBattleScreen> {
  PvpPhase _phase = PvpPhase.lobby;
  final _usernameController = TextEditingController();

  String? _roomId;
  bool _isHost = false;
  String? _myId;
  String _myUsername = '';
  String _opponentUsername = '';

  // Battle state
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _selectedOption = -1;
  bool _showResult = false;
  int _myScore = 0;
  int _opponentScore = 0;

  // Countdown
  int _countdown = 5;
  Timer? _countdownTimer;

  // Per-question timer
  int _questionTime = 15;
  Timer? _questionTimer;

  // Realtime
  RealtimeChannel? _channel;

  bool _isSending = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _myId = AuthService.currentUser?.id;
    _loadMyUsername();

    if (widget.roomId != null) {
      _roomId = widget.roomId;
      _isHost = false;
      _phase = PvpPhase.accepted;
      _joinRoom();
    }
  }

  Future<void> _loadMyUsername() async {
    final profile = await AuthService.getCurrentUserProfile();
    if (mounted && profile != null) {
      setState(() => _myUsername = profile.username);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _countdownTimer?.cancel();
    _questionTimer?.cancel();
    if (_channel != null) PvpService.unsubscribeFromRoom(_channel!);
    super.dispose();
  }

  // ─── LOBBY: Create room & send invite ───
  Future<void> _createAndInvite() async {
    final guestUsername = _usernameController.text.trim();
    if (guestUsername.isEmpty) {
      setState(() => _errorMsg = 'Vui lòng nhập tên người chơi');
      return;
    }
    setState(() {
      _isSending = true;
      _errorMsg = null;
    });
    try {
      final room = await PvpService.createRoom(_myId!);
      _roomId = room['id'] as String;
      _isHost = true;
      final sent = await PvpService.sendInvite(
        roomId: _roomId!,
        hostUsername: _myUsername,
        guestUsername: guestUsername,
      );
      if (!sent) {
        setState(() {
          _isSending = false;
          _errorMsg = 'Không tìm thấy người chơi "$guestUsername"';
        });
        return;
      }
      _opponentUsername = guestUsername;
      _subscribeToRoom();
      setState(() {
        _isSending = false;
        _phase = PvpPhase.waiting;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMsg = 'Lỗi: $e';
        });
      }
    }
  }

  // ─── JOIN: Guest joins the room ───
  Future<void> _joinRoom() async {
    try {
      final room = await PvpService.getRoom(_roomId!);
      final hostData = await Supabase.instance.client
          .from('users')
          .select('username')
          .eq('id', room['host_id'])
          .single();
      _opponentUsername = hostData['username'] ?? 'Đối thủ';
      await PvpService.acceptInvite(_roomId!);
      _subscribeToRoom();
      if (mounted) setState(() => _phase = PvpPhase.accepted);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = 'Lỗi kết nối phòng: $e');
      }
    }
  }

  // ─── SUBSCRIBE to realtime room changes ───
  void _subscribeToRoom() {
    _channel = PvpService.subscribeToRoom(_roomId!, (newData) {
      if (!mounted) return;
      final status = newData['status'] as String? ?? '';
      final hostReady = newData['host_ready'] == true;
      final guestReady = newData['guest_ready'] == true;

      setState(() {
        if (_isHost) {
          _opponentScore = newData['guest_score'] as int? ?? 0;
        } else {
          _opponentScore = newData['host_score'] as int? ?? 0;
        }
      });

      if (status == 'accepted' && _phase == PvpPhase.waiting) {
        setState(() => _phase = PvpPhase.accepted);
      }
      if (hostReady && guestReady && _phase == PvpPhase.accepted) {
        _startCountdown();
      }
      if (status == 'playing' && _phase == PvpPhase.countdown) {
        if (!_isHost && _questions.isEmpty) _loadQuestionsForGuest();
      }
      if (status == 'finished' && _phase != PvpPhase.finished) {
        _questionTimer?.cancel();
        setState(() {
          _myScore = _isHost
              ? (newData['host_score'] as int? ?? 0)
              : (newData['guest_score'] as int? ?? 0);
          _opponentScore = _isHost
              ? (newData['guest_score'] as int? ?? 0)
              : (newData['host_score'] as int? ?? 0);
          _phase = PvpPhase.finished;
        });
      }
    });
  }

  Future<void> _setReady() async {
    await PvpService.setReady(_roomId!, _myId!);
  }

  void _startCountdown() {
    setState(() {
      _phase = PvpPhase.countdown;
      _countdown = 5;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        _beginBattle();
      }
    });
  }

  Future<void> _beginBattle() async {
    if (_isHost) {
      final questions = await PvpService.startGame(_roomId!);
      if (mounted) {
        setState(() {
          _questions = questions;
          _currentIndex = 0;
          _phase = PvpPhase.playing;
        });
        _startQuestionTimer();
      }
    }
  }

  Future<void> _loadQuestionsForGuest() async {
    final questions = await PvpService.getRoomQuestions(_roomId!);
    if (mounted) {
      setState(() {
        _questions = questions;
        _currentIndex = 0;
        _phase = PvpPhase.playing;
      });
      _startQuestionTimer();
    }
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    setState(() => _questionTime = 15);
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _questionTime--);
      if (_questionTime <= 0) {
        timer.cancel();
        _autoSkipQuestion();
      }
    });
  }

  void _autoSkipQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = -1;
        _showResult = false;
      });
      _startQuestionTimer();
    } else {
      _endGame();
    }
  }

  Future<void> _selectAnswer(int index) async {
    if (_selectedOption != -1 || _questions.isEmpty) return;
    _questionTimer?.cancel();
    final q = _questions[_currentIndex];
    final labels = ['A', 'B', 'C', 'D'];
    final answer = labels[index];
    final isCorrect = answer == q.correctAnswer;
    setState(() {
      _selectedOption = index;
      _showResult = true;
      if (isCorrect) {
        _myScore += 100 + (_questionTime * 5);
      } else {
        _myScore = (_myScore - 30).clamp(0, 999999);
      }
    });
    await PvpService.submitAnswer(
      roomId: _roomId!,
      userId: _myId!,
      questionId: q.id,
      questionIndex: _currentIndex,
      answer: answer,
      correctAnswer: q.correctAnswer,
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOption = -1;
          _showResult = false;
        });
        _startQuestionTimer();
      } else {
        _endGame();
      }
    });
  }

  Future<void> _endGame() async {
    _questionTimer?.cancel();
    await PvpService.finishGame(_roomId!);
  }

  // ═══════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        title: const Text('Thách đấu PvP'),
      ),
      body: switch (_phase) {
        PvpPhase.lobby => _buildLobby(),
        PvpPhase.waiting => _buildWaiting(),
        PvpPhase.accepted => _buildAccepted(),
        PvpPhase.countdown => _buildCountdown(),
        PvpPhase.playing => _buildPlaying(),
        PvpPhase.finished => _buildFinished(),
      },
    );
  }

  // ─── LOBBY ───
  Widget _buildLobby() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.sports_esports_rounded,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Tạo phòng thách đấu',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập tên người chơi bạn muốn thách đấu',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Nhập username đối thủ...',
              prefixIcon: const Icon(Icons.person_search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMsg!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isSending ? null : _createAndInvite,
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_isSending ? 'Đang gửi...' : 'Gửi lời mời'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── WAITING ───
  Widget _buildWaiting() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              'Đang chờ đối thủ...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Đã gửi lời mời đến $_opponentUsername',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Đối thủ sẽ nhận lời mời qua thông báo',
              style: TextStyle(color: AppColors.textHint, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACCEPTED ───
  Widget _buildAccepted() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: AppColors.accentGreen,
            ),
            const SizedBox(height: 24),
            Text(
              _isHost
                  ? '$_opponentUsername đã chấp nhận!'
                  : 'Bạn đã vào phòng của $_opponentUsername',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn "Sẵn sàng" để bắt đầu',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _playerChip(_myUsername, AppColors.primary),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  _playerChip(_opponentUsername, const Color(0xFFE11D48)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _setReady,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Sẵn sàng!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerChip(String name, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withAlpha(30),
          child: Icon(Icons.person, size: 28, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  // ─── COUNTDOWN ───
  Widget _buildCountdown() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_countdown',
            style: TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chuẩn bị...',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ─── PLAYING ───
  Widget _buildPlaying() {
    if (_questions.isEmpty)
      return const Center(child: CircularProgressIndicator());
    final q = _questions[_currentIndex];
    final labels = ['A', 'B', 'C', 'D'];
    final options = [q.optionA, q.optionB, q.optionC, q.optionD];

    return Column(
      children: [
        // Score bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _myUsername,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$_myScore',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _questionTime <= 5
                          ? Colors.red.withAlpha(25)
                          : AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_questionTime}s',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _questionTime <= 5
                            ? Colors.red
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentIndex + 1}/${_questions.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _opponentUsername,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$_opponentScore',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Question & options
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    q.question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                for (int i = 0; i < options.length; i++) ...[
                  QuizOptionButton(
                    label: labels[i],
                    text: options[i],
                    isSelected: _selectedOption == i,
                    isCorrect: labels[i] == q.correctAnswer,
                    showResult: _showResult,
                    onTap: () => _selectAnswer(i),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── FINISHED ───
  Widget _buildFinished() {
    final won = _myScore > _opponentScore;
    final draw = _myScore == _opponentScore;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              draw
                  ? Icons.handshake_rounded
                  : won
                  ? Icons.emoji_events_rounded
                  : Icons.sentiment_dissatisfied_rounded,
              size: 80,
              color: draw
                  ? AppColors.accentGold
                  : won
                  ? AppColors.accentGold
                  : AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              draw
                  ? 'Hòa!'
                  : won
                  ? 'Chiến thắng! 🎉'
                  : 'Thua cuộc 😥',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: draw
                    ? AppColors.accentGold
                    : won
                    ? AppColors.accentGreen
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _myUsername,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_myScore',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text('điểm'),
                      ],
                    ),
                  ),
                  const Text(
                    'VS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _opponentUsername,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_opponentScore',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                        const Text('điểm'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Quay về',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

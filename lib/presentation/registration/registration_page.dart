import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/notifications/notification_service.dart';
import '../../data/repositories/registration_repository.dart';
import '../posts/posts_page.dart';
import 'registration_cubit.dart';
import 'registration_validators.dart';

class RegistrationPage extends StatelessWidget {
  /// [isInitial] — экран открыт при запуске: после регистрации
  /// заменяется списком постов, иначе просто закрывается.
  const RegistrationPage({super.key, this.isInitial = false});

  final bool isInitial;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegistrationCubit(
        context.read<RegistrationRepository>(),
        context.read<PushNotifications>(),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Регистрация')),
        body: _RegistrationForm(isInitial: isInitial),
      ),
    );
  }
}

class _RegistrationForm extends StatefulWidget {
  const _RegistrationForm({required this.isInitial});

  final bool isInitial;

  @override
  State<_RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<_RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<RegistrationCubit>().submit(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          city: _city.text,
        );
  }

  void _onSuccess(RegistrationState state) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Готово! Ключ записи в базе: ${state.userKey}')),
    );
    final navigator = Navigator.of(context);
    if (widget.isInitial) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const PostsPage()),
      );
    } else {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final token = context.read<PushNotifications>().token;

    return BlocConsumer<RegistrationCubit, RegistrationState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == RegistrationStatus.success) {
          _onSuccess(state);
        } else if (state.status == RegistrationStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error?.message ?? 'Не удалось зарегистрироваться'),
            ),
          );
        }
      },
      builder: (context, state) {
        final locked = state.isSubmitting ||
            state.status == RegistrationStatus.success;
        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Данные сохранятся в Firebase Realtime Database, '
                'после регистрации придёт уведомление.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                enabled: !locked,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: RegistrationValidators.name,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                enabled: !locked,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: RegistrationValidators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                enabled: !locked,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+7 700 123 45 67',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: RegistrationValidators.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _city,
                enabled: !locked,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Город (необязательно)',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                validator: RegistrationValidators.city,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: locked ? null : _submit,
                icon: state.isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.how_to_reg_outlined),
                label: Text(
                  state.isSubmitting ? 'Сохраняем…' : 'Зарегистрироваться',
                ),
              ),
              if (widget.isInitial)
                TextButton(
                  onPressed: locked
                      ? null
                      : () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const PostsPage(),
                            ),
                          ),
                  child: const Text('Пропустить'),
                ),
              const SizedBox(height: 24),
              _TokenCard(token: token),
            ],
          ),
        );
      },
    );
  }
}

/// FCM-токен устройства: нужен, чтобы отправить тестовый пуш
/// из Firebase Console (Messaging → «Send test message»).
class _TokenCard extends StatelessWidget {
  const _TokenCard({required this.token});

  final String? token;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = token;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FCM-токен устройства', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    value ?? 'Недоступен (Firebase не настроен или нет сети)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (value != null)
              IconButton(
                tooltip: 'Скопировать',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Токен скопирован')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

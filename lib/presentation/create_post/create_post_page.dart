import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/post.dart';
import '../../data/repositories/posts_repository.dart';
import '../widgets/state_views.dart';
import 'create_post_cubit.dart';
import 'post_validators.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CreatePostCubit(context.read<PostsRepository>())..loadUsers(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Новый пост')),
        body: BlocBuilder<CreatePostCubit, CreatePostState>(
          buildWhen: (a, b) =>
              a.usersStatus != b.usersStatus || a.users != b.users,
          builder: (context, state) => switch (state.usersStatus) {
            UsersStatus.loading => const LoadingView(),
            UsersStatus.error => MessageView(
                icon: Icons.people_outline,
                title: 'Не удалось загрузить список авторов',
                message: state.error?.message,
                actionLabel: 'Повторить',
                onAction: () => context.read<CreatePostCubit>().loadUsers(),
              ),
            UsersStatus.success => const _CreatePostForm(),
          },
        ),
      ),
    );
  }
}

class _CreatePostForm extends StatefulWidget {
  const _CreatePostForm();

  @override
  State<_CreatePostForm> createState() => _CreatePostFormState();
}

class _CreatePostFormState extends State<_CreatePostForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  int? _userId;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CreatePostCubit>().submit(
          userId: _userId!,
          title: _title.text,
          body: _body.text,
        );
  }

  Future<void> _showServerResponse(Post created) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline),
        title: const Text('Пост отправлен'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ответ сервера (201):'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(created.toJson()),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'JSONPlaceholder не сохраняет данные, поэтому пост добавлен '
                'в список с пометкой «создан локально».',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('К списку'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreatePostCubit, CreatePostState>(
      listenWhen: (a, b) => a.submitStatus != b.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == SubmitStatus.success &&
            state.created != null) {
          _showServerResponse(state.created!);
        } else if (state.submitStatus == SubmitStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error?.message ?? 'Не удалось отправить'),
            ),
          );
        }
      },
      builder: (context, state) {
        final locked = state.isSubmitting ||
            state.submitStatus == SubmitStatus.success;
        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<int>(
                initialValue: _userId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Автор',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: [
                  for (final u in state.users)
                    DropdownMenuItem(value: u.id, child: Text(u.name)),
                ],
                validator: PostValidators.userId,
                onChanged: locked ? null : (v) => setState(() => _userId = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                enabled: !locked,
                maxLength: PostValidators.titleMax,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  helperText:
                      'От ${PostValidators.titleMin} до ${PostValidators.titleMax} символов',
                ),
                validator: PostValidators.title,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _body,
                enabled: !locked,
                minLines: 4,
                maxLines: 10,
                maxLength: PostValidators.bodyMax,
                decoration: const InputDecoration(
                  labelText: 'Текст',
                  alignLabelWithHint: true,
                  helperText:
                      'От ${PostValidators.bodyMin} до ${PostValidators.bodyMax} символов',
                ),
                validator: PostValidators.body,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                // Пока идёт запрос — кнопка заблокирована.
                onPressed: locked ? null : _submit,
                icon: state.isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(state.isSubmitting ? 'Отправка…' : 'Опубликовать'),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:careerai_coach/data/models/models.dart';
import 'package:careerai_coach/data/providers/providers.dart';
import 'package:careerai_coach/features/shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(sessionUserProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return CareerScaffold(
          title: 'Тарифы',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const HeroBanner(
                title: 'Простая модель тарифов',
                subtitle:
                    'Бесплатный тариф для базового анализа, премиум для более глубокой помощи и B2B для университетов и компаний.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  _planCard(
                    context,
                    user.id!,
                    'Бесплатный',
                    'Базовый анализ, ограниченный план развития, недельные задачи',
                    UserPlan.free,
                    user.plan,
                  ),
                  _planCard(
                    context,
                    user.id!,
                    'Премиум',
                    'Более глубокий анализ, больше задач в плане, улучшение резюме',
                    UserPlan.premium,
                    user.plan,
                  ),
                  _planCard(
                    context,
                    user.id!,
                    'B2B',
                    'Панели развития навыков для университетов и компаний',
                    UserPlan.b2b,
                    user.plan,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
    );
  }

  Widget _planCard(
    BuildContext context,
    int userId,
    String title,
    String subtitle,
    UserPlan plan,
    UserPlan current,
  ) {
    final selected = current == plan;
    return SizedBox(
      width: 310,
      child: InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(subtitle),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selected || _submitting
                    ? null
                    : () => _handlePlanChange(userId, plan),
                child: Text(
                  selected
                      ? 'Текущий тариф'
                      : plan == UserPlan.free
                      ? 'Переключить тариф'
                      : 'Оформить с оплатой',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePlanChange(int userId, UserPlan plan) async {
    if (plan == UserPlan.free) {
      await _updatePlan(userId, plan);
      return;
    }

    final confirmed = await _showPaymentDialog(context, plan);
    if (confirmed != true || !context.mounted) return;
    await _updatePlan(userId, plan);
  }

  Future<void> _updatePlan(int userId, UserPlan plan) async {
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).updatePlan(userId, plan);
      refreshSessionData(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            plan == UserPlan.free
                ? 'Тариф переключен на бесплатный.'
                : 'Оплата прошла успешно. Тариф ${plan == UserPlan.premium ? 'Премиум' : 'B2B'} активирован.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<bool?> _showPaymentDialog(BuildContext context, UserPlan plan) {
    final formKey = GlobalKey<FormState>();
    final cardNumber = TextEditingController();
    final cardHolder = TextEditingController();
    final expiry = TextEditingController();
    final cvv = TextEditingController();

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            plan == UserPlan.premium
                ? 'Оплата тарифа Премиум'
                : 'Подключение тарифа B2B',
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    plan == UserPlan.premium
                        ? 'Введите данные карты для подключения премиум-доступа.'
                        : 'Введите данные карты для подключения B2B-доступа.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cardNumber,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Номер карты',
                      hintText: '4242 4242 4242 4242',
                    ),
                    validator: (value) {
                      final digits = value?.replaceAll(' ', '') ?? '';
                      if (digits.length < 16) {
                        return 'Введите корректный номер карты.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cardHolder,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Имя на карте',
                      hintText: 'IVAN IVANOV',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 4) {
                        return 'Введите имя владельца карты.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: expiry,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(
                            labelText: 'Срок действия',
                            hintText: '12/28',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(text)) {
                              return 'Формат MM/YY';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: cvv,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'CVV'),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.length < 3) {
                              return 'Введите CVV.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context, true);
              },
              child: const Text('Оплатить'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      cardNumber.dispose();
      cardHolder.dispose();
      expiry.dispose();
      cvv.dispose();
    });
  }
}

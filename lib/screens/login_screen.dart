import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../utils/validators.dart';
import '../widgets/comum.dart';
import 'inicio_shell.dart';

class LoginScreen extends StatefulWidget {
  final bool sessaoExpirada;

  const LoginScreen({super.key, this.sessaoExpirada = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _carregando = false;
  bool _mostrarSenha = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    if (widget.sessaoExpirada) _erro = 'Sua sessão expirou. Entre novamente.';
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resp = await Api.instancia.post('/login', {
        'email': _email.text.trim().toLowerCase(),
        'senha': _senha.text,
      });
      await Api.instancia.salvarToken(resp['token']);
      final aluno = Aluno.fromJson(resp['aluno']);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InicioShell(aluno: aluno)));
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Fundo(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Logo(),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CCAM', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: 0.4)),
                            Text('Controle & acompanhamento', style: TextStyle(color: Cores.textoFraco, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    const Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.6),
                        children: [
                          TextSpan(text: 'Seu treino '),
                          TextSpan(text: 'na palma da mão', style: TextStyle(color: Cores.lilas)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Veja a ficha montada pelo seu professor, marque o que já treinou e acompanhe a sua frequência.',
                      style: TextStyle(color: Cores.textoSuave, fontSize: 14.5, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    Cartao(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Acesse sua conta', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            const Text('Use o e-mail cadastrado na academia. No primeiro acesso, a senha é o seu CPF.',
                                style: TextStyle(color: Cores.textoSuave, fontSize: 13.5)),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                              ),
                              validator: Validators.validaEmail,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _senha,
                              obscureText: !_mostrarSenha,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _entrar(),
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  tooltip: _mostrarSenha ? 'Ocultar' : 'Mostrar',
                                  icon: Icon(_mostrarSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                  onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                                ),
                              ),
                              validator: Validators.validaSenha,
                            ),
                            if (_erro != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0x1FEF4444),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0x61EF4444)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Cores.vermelhoClaro, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(_erro!, style: const TextStyle(color: Cores.vermelhoClaro, fontSize: 13.5))),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            BotaoMarca(texto: 'Entrar', icone: Icons.arrow_forward_rounded, carregando: _carregando, onPressed: _entrar),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Não consegue entrar? Fale com a recepção da sua academia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Cores.textoFraco, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

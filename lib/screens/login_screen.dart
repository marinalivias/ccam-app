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

  Future<void> _esqueciSenha() async {
    final email = TextEditingController(text: _email.text.trim());
    final chave = GlobalKey<FormState>();
    var enviando = false;
    String? resposta;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Form(
            key: chave,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Esqueci minha senha', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text(
                  'Avisamos a recepção da sua academia. Quando ela redefinir, você entra com o e-mail e o seu CPF e pode criar uma senha nova no perfil.',
                  style: TextStyle(color: Cores.textoSuave, height: 1.4),
                ),
                const SizedBox(height: 16),
                if (resposta != null)
                  Cartao(
                    corBorda: const Color(0x6122C55E),
                    child: Row(
                      children: [
                        const IconeChip(Icons.mark_email_read_rounded, cor: Cores.verde),
                        const SizedBox(width: 12),
                        Expanded(child: Text(resposta!, style: const TextStyle(height: 1.4))),
                      ],
                    ),
                  )
                else ...[
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail cadastrado', prefixIcon: Icon(Icons.mail_outline_rounded, size: 20)),
                    validator: Validators.validaEmail,
                  ),
                  const SizedBox(height: 16),
                  BotaoMarca(
                    texto: 'Avisar a recepção',
                    icone: Icons.send_rounded,
                    carregando: enviando,
                    onPressed: () async {
                      if (!chave.currentState!.validate()) return;
                      setSheet(() => enviando = true);
                      try {
                        final r = await Api.instancia.post('/esqueci-senha', {'email': email.text.trim().toLowerCase()});
                        setSheet(() => resposta = (r is Map ? r['mensagem'] : null)?.toString() ?? 'Pedido enviado.');
                      } on ApiException catch (e) {
                        setSheet(() => enviando = false);
                        if (ctx.mounted) mostrarMensagem(ctx, e.mensagem, erro: true);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(onPressed: _esqueciSenha, child: const Text('Esqueci minha senha')),
                            ),
                            const SizedBox(height: 6),
                            BotaoMarca(texto: 'Entrar', icone: Icons.arrow_forward_rounded, carregando: _carregando, onPressed: _entrar),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Ainda não tem acesso? Fale com a recepção da sua academia.',
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

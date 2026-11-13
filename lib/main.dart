import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'models.dart';
import 'screens/inicio_shell.dart';
import 'screens/login_screen.dart';
import 'theme.dart';
import 'widgets/comum.dart';

final navegador = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0F1B),
  ));
  await Api.instancia.carregarToken();
  Api.instancia.aoExpirar = () {
    navegador.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen(sessaoExpirada: true)),
      (_) => false,
    );
  };
  runApp(const CcamApp());
}

class CcamApp extends StatelessWidget {
  const CcamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navegador,
      debugShowCheckedModeBanner: false,
      title: 'CCAM',
      theme: temaCcam(),
      home: Api.instancia.logado ? const _Abertura() : const LoginScreen(),
    );
  }
}

class _Abertura extends StatefulWidget {
  const _Abertura();

  @override
  State<_Abertura> createState() => _AberturaState();
}

class _AberturaState extends State<_Abertura> {
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final aluno = Aluno.fromJson(await Api.instancia.get('/me'));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InicioShell(aluno: aluno)));
    } on ApiException catch (e) {
      if (e.status == 401 || !mounted) return;
      setState(() => _erro = e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Fundo(
        child: Center(
          child: _erro == null
              ? const Logo(tamanho: 64)
              : Erro(mensagem: _erro!, onTentar: _carregar),
        ),
      ),
    );
  }
}

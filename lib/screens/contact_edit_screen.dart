import 'package:flutter/material.dart';
import 'package:teste/models/contact_model.dart';
import 'package:teste/utils/database_helper.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ContactEditScreen extends StatefulWidget {
  final Contact? contact;
  const ContactEditScreen({super.key, this.contact});

  @override
  State<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends State<ContactEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditing;
  late bool _isFavorite;

  late TextEditingController _nomeController;
  late TextEditingController _sobrenomeController;
  late TextEditingController _telefoneController;
  late TextEditingController _emailController;
  late TextEditingController _dataNascController;
  
  late TextEditingController _cepController;
  late TextEditingController _enderecoController;
  late TextEditingController _bairroController;
  late TextEditingController _cidadeController;
  late TextEditingController _estadoController;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  
  final _dateFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _isEditing = widget.contact != null;
    _isFavorite = _isEditing ? widget.contact!.isFavorite : false;

    _nomeController = TextEditingController(text: _isEditing ? widget.contact!.nome : '');
    _sobrenomeController = TextEditingController(text: _isEditing ? widget.contact!.sobrenome : '');
    _telefoneController = TextEditingController(text: _isEditing ? widget.contact!.telefone : '');
    _emailController = TextEditingController(text: _isEditing ? widget.contact!.email : '');
    _dataNascController = TextEditingController(text: _isEditing ? widget.contact!.dataNascimento : '');
    
    _cepController = TextEditingController(text: _isEditing ? widget.contact!.cep : '');
    _enderecoController = TextEditingController(text: _isEditing ? widget.contact!.endereco : '');
    _bairroController = TextEditingController(text: _isEditing ? widget.contact!.bairro : '');
    _cidadeController = TextEditingController(text: _isEditing ? widget.contact!.cidade : '');
    _estadoController = TextEditingController(text: _isEditing ? widget.contact!.estado : '');

    if (_telefoneController.text.isNotEmpty) {
      _telefoneController.text = _phoneFormatter.maskText(_telefoneController.text);
    }
    if (_dataNascController.text.isNotEmpty) {
      _dataNascController.text = _dateFormatter.maskText(_dataNascController.text);
    }
    if (_cepController.text.isNotEmpty) {
      _cepController.text = _cepFormatter.maskText(_cepController.text);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _dataNascController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _buscarCep() async {
    String cep = _cepFormatter.getUnmaskedText();
    
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um CEP válido para buscar!')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final response = await http.get(url);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('erro')) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CEP não encontrado!')));
        } else {
          setState(() {
            _enderecoController.text = data['logradouro'] ?? '';
            _bairroController.text = data['bairro'] ?? '';
            _cidadeController.text = data['localidade'] ?? '';
            _estadoController.text = data['uf'] ?? '';
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro no servidor')));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro de conexão: $e')));
    }
  }

  Future<void> _saveContact() async {
    if (_formKey.currentState!.validate()) {
      final contact = Contact(
        id: _isEditing ? widget.contact!.id : null,
        nome: _nomeController.text,
        sobrenome: _sobrenomeController.text,
        telefone: _phoneFormatter.unmaskText(_telefoneController.text),
        email: _emailController.text,
        dataNascimento: _dataNascController.text,
        isFavorite: _isFavorite,
        cep: _cepFormatter.unmaskText(_cepController.text),
        endereco: _enderecoController.text,
        bairro: _bairroController.text,
        cidade: _cidadeController.text,
        estado: _estadoController.text,
      );

      if (_isEditing) {
        await DatabaseHelper.instance.update(contact);
      } else {
        await DatabaseHelper.instance.create(contact);
      }
      _showSuccessScreen();
    }
  }

  Future<void> _deleteContact() async {
    if (!_isEditing) return;
    final bool? shouldDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Você tem certeza que quer deletar este contato?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Deletar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldDelete == true) {
      await DatabaseHelper.instance.delete(widget.contact!.id!);
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    }
  }

  void _showSuccessScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.of(dialogContext).pop(); 
          if (mounted) Navigator.of(context).pop('edited'); 
        });
        return const Dialog(
          backgroundColor: Color(0xFFC0A080),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 40, backgroundColor: Color(0xFFFFF8F0)),
                SizedBox(height: 20),
                Text("Contato Salvo!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now();
    if (_dataNascController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parse(_dataNascController.text);
      } catch (e) { }
    }
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: initialDate, firstDate: DateTime(1900), lastDate: DateTime.now(),
    );
    if (picked != null && picked != initialDate) {
      setState(() { _dataNascController.text = DateFormat('dd/MM/yyyy').format(picked); });
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isCep = false}) {
    TextInputType keyboardType = TextInputType.text;
    List<MaskTextInputFormatter> inputFormatters = [];
    Widget? suffixIcon;

    if (label == 'Telefone') {
      keyboardType = TextInputType.phone;
      inputFormatters = [_phoneFormatter];
    } else if (label == 'Data de Nascimento') {
      keyboardType = TextInputType.datetime;
      inputFormatters = [_dateFormatter];
      suffixIcon = IconButton(icon: const Icon(Icons.calendar_month, color: Colors.brown), onPressed: _selectDate);
    } else if (isCep) {
      keyboardType = TextInputType.number;
      inputFormatters = [_cepFormatter];
      suffixIcon = IconButton(
        icon: const Icon(Icons.search, color: Colors.brown),
        onPressed: _buscarCep,
        tooltip: 'Buscar CEP',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFDBC8B0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: suffixIcon,
            ),
            validator: (value) {
              if (label == 'Nome' && (value == null || value.isEmpty)) return 'O nome é obrigatório';
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Contato' : 'Adicionar Contato'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.brown[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFDBC8B0),
                child: _nomeController.text.isNotEmpty
                    ? Text(_nomeController.text[0].toUpperCase(), style: const TextStyle(fontSize: 48, color: Colors.white))
                    : const Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              
              _buildTextField('Nome', _nomeController),
              _buildTextField('Sobrenome', _sobrenomeController),
              _buildTextField('Telefone', _telefoneController),
              _buildTextField('E-mail', _emailController),
              _buildTextField('Data de Nascimento', _dataNascController),
              
              const Divider(height: 40, thickness: 2, color: Color(0xFFC0A080)),
              const Align(
                alignment: Alignment.centerLeft, 
                child: Text(" Endereço", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown))
              ),
              const SizedBox(height: 10),
              
              _buildTextField('CEP', _cepController, isCep: true),
              Row(children: [
                Expanded(child: _buildTextField('Cidade', _cidadeController)),
                const SizedBox(width: 10),
                Expanded(flex: 1, child: _buildTextField('UF', _estadoController)),
              ]),
              _buildTextField('Bairro', _bairroController),
              _buildTextField('Endereço', _enderecoController),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveContact,
                  icon: const Icon(Icons.save),
                  label: const Text("SALVAR CONTATO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFFFF8F0),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(_isFavorite ? Icons.star : Icons.star_outline, color: _isFavorite ? Colors.amber[700] : Colors.grey[700], size: 30),
                onPressed: () { setState(() { _isFavorite = !_isFavorite; }); },
              ),
              if (_isEditing)
                IconButton(icon: Icon(Icons.delete_outline, color: Colors.red[700], size: 30), onPressed: _deleteContact),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:teste/models/contact_model.dart';
import 'package:teste/screens/contact_edit_screen.dart';
import 'package:teste/screens/contact_view_screen.dart';
import 'package:teste/utils/database_helper.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';


class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  late Future<List<Contact>> _contactsFuture;
  
  bool _isSearching = false;
  final _searchController = TextEditingController();

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _refreshContactList();
  }

  void _refreshContactList() {
    setState(() {
      _contactsFuture = DatabaseHelper.instance.getAllContacts(
        query: _searchController.text,
      );
    });
  }

  void _navigateToEditScreen([Contact? contact]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactEditScreen(contact: contact),
      ),
    );
    
    if (result == 'edited') {
      _refreshContactList();
    }
  }

  void _navigateToViewScreen(int contactId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactViewScreen(contactId: contactId),
      ),
    );

    if (result == true) {
      _refreshContactList();
    }
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Buscar contato...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 18),
      onChanged: (query) => _refreshContactList(),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
            });
            _refreshContactList();
          },
        ),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _navigateToEditScreen(),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching ? _buildSearchField() : const Text('Meus Contatos'),
        backgroundColor: const Color(0xFFC0A080),
        actions: _buildAppBarActions(),
      ),
      body: FutureBuilder<List<Contact>>(
        future: _contactsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar contatos: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhum contato cadastrado."));
          }

          final contacts = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];

              String formattedPhone = contact.telefone ?? 'Sem telefone';
              if (contact.telefone != null && contact.telefone!.isNotEmpty) {
                formattedPhone = _phoneFormatter.maskText(contact.telefone!);
              }

              return Card(
                color: const Color(0xFFDBC8B0),
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFC0A080),
                    child: Text(
                      contact.nome.isNotEmpty ? contact.nome[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    '${contact.nome} ${contact.sobrenome ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(formattedPhone),
                  trailing: contact.isFavorite
                      ? Icon(Icons.star, color: Colors.amber[700])
                      : null,
                  onTap: () => _navigateToViewScreen(contact.id!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
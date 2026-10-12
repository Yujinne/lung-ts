import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home.dart';

class MedicineRegistrationScreen extends StatefulWidget {
  final String token;

  const MedicineRegistrationScreen({
    super.key,
    required this.token,
  });

  @override
  State<MedicineRegistrationScreen> createState() =>
      _MedicineRegistrationScreenState();
}

class _MedicineRegistrationScreenState
    extends State<MedicineRegistrationScreen> {
  final medicineSearchController = TextEditingController();

  final List<Map<String, dynamic>> selectedMedicines = [];

  bool isSearching = false;

  @override
  void dispose() {
    medicineSearchController.dispose();
    super.dispose();
  }

  Future<void> searchMedicines() async {
    final keyword = medicineSearchController.text.trim();

    if (keyword.isEmpty || isSearching) return;

    setState(() {
      isSearching = true;
    });

    try {
      final uri = Uri.parse(
        'http://localhost:8080/api/medicines/search-list',
      ).replace(
        queryParameters: {'name': keyword},
      );

      final response = await http.get(uri);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        final results = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        if (results.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('검색 결과가 없습니다.')),
          );
          return;
        }

        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('약 검색 결과'),
              content: SizedBox(
                width: 400,
                height: 350,
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final medicine = results[index];

                    final name =
                        medicine['itemName']?.toString() ?? '';

                    return ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () {
                        if (name.isEmpty) return;

                        final itemSeq =
                            medicine['itemSeq']?.toString() ?? '';

                        setState(() {
                          final exists = selectedMedicines.any(
                                (item) =>
                            item['itemSeq']?.toString() == itemSeq,
                          );

                          if (!exists) {
                            selectedMedicines.add(medicine);
                          }

                          medicineSearchController.clear();
                        });

                        Navigator.pop(dialogContext);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('약 검색 실패 (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('약 검색 오류: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  bool isRegistering = false;

  Future<void> registerMedicines() async {
    if (selectedMedicines.isEmpty || isRegistering) return;

    setState(() {
      isRegistering = true;
    });

    try {
      // 선택한 약 전체를 하나의 목록으로 변환
      final medicines = selectedMedicines.map((medicine) {
        return {
          'medicineCode': medicine['itemSeq'].toString(),
          'doseUnit': null,
        };
      }).toList();

      // 선택한 약 전체를 한 번에 서버로 전송
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/user-medicines/bulk'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'medicines': medicines,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
              (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('선택한 약이 모두 등록되었습니다.'),
          ),
        );
      } else {
        final message = utf8.decode(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('약 등록 실패: $message'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('서버 연결 오류: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('복용 중인 약 등록'),
        backgroundColor: const Color(0xFFF9FAFB),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '현재 복용 중인 약을 검색해 주세요.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                '여러 개의 약을 선택할 수 있어요.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: medicineSearchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => searchMedicines(),
                decoration: InputDecoration(
                  hintText: '약 이름 검색',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF3678C8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: isSearching ? null : searchMedicines,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (isSearching)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

              const SizedBox(height: 24),

              const Text(
                '선택한 약',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: selectedMedicines.isEmpty
                    ? const Center(
                  child: Text(
                    '아직 선택한 약이 없어요.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: selectedMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = selectedMedicines[index];

                    return Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: const Icon(
                          Icons.medication,
                          color: Color(0xFF3678C8),
                        ),
                        title: Text(
                          medicine['itemName']?.toString() ?? '',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              selectedMedicines.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedMedicines.isEmpty || isRegistering
                      ? null
                      : registerMedicines,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3678C8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isRegistering ? '등록 중...' : '등록 완료',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
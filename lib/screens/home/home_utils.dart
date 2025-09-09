// Utility functions for Home Screen
String getPartySymbolPath(String party) {
  final partyMapping = {
    'Indian National Congress': 'inc.png',
    'Bharatiya Janata Party': 'bjp.png',
    'Nationalist Congress Party (Ajit Pawar faction)': 'ncp_ajit.png',
    'Nationalist Congress Party – Sharadchandra Pawar': 'ncp_sp.png',
    'Shiv Sena (Eknath Shinde faction)': 'shiv_sena_shinde.png',
    'Shiv Sena (Uddhav Balasaheb Thackeray – UBT)': 'shiv_sena_ubt.jpeg',
    'Maharashtra Navnirman Sena': 'mns.png',
    'Communist Party of India': 'cpi.png',
    'Communist Party of India (Marxist)': 'cpi_m.png',
    'Bahujan Samaj Party': 'bsp.png',
    'Samajwadi Party': 'sp.png',
    'All India Majlis-e-Ittehad-ul-Muslimeen': 'aimim.png',
    'National Peoples Party': 'npp.png',
    'Peasants and Workers Party of India': 'pwp.jpg',
    'Vanchit Bahujan Aaghadi': 'vba.png',
  };

  final symbolFile = partyMapping[party] ?? 'default.png';
  return 'assets/symbols/$symbolFile';
}
export const church = {
  brand: 'Primeira IPI Avaré',
  shortName: 'IPI Avaré',
  fullName: 'Primeira Igreja Presbiteriana Independente de Avaré',
  denomination: 'Igreja Presbiteriana Independente do Brasil',
  tagline: 'Uma comunidade guiada pela Palavra',
  mission:
    'Somos uma igreja cristã que procura viver os ensinamentos de Cristo, tornando-os relevantes para o nosso tempo — com acolhimento, adoração e serviço em Avaré.',
  pastor: 'Rev. Alessandro Richter',
  address: {
    street: 'Rua Goiás, 1142',
    neighborhood: 'Centro',
    city: 'Avaré',
    state: 'SP',
    zip: '18700-140',
    full: 'Rua Goiás, 1142 — Centro, Avaré/SP — CEP 18700-140',
  },
  phone: '(14) 3733-3020',
  phoneHref: 'tel:+551437333020',
  email: 'primeiraipiavare@gmail.com',
  emailHref: 'mailto:primeiraipiavare@gmail.com',
  mapUrl:
    'https://www.google.com/maps/search/?api=1&query=Rua+Goi%C3%A1s+1142+Avar%C3%A9+SP',
  services: [
    {
      day: 'Domingo',
      time: '09h00',
      title: 'Culto matutino',
      note: 'Adoração, Palavra e comunhão',
    },
    {
      day: 'Domingo',
      time: '19h00',
      title: 'Culto noturno',
      note: 'Venha como está — você é bem-vindo',
    },
    {
      day: 'Quarta',
      time: '19h30',
      title: 'Estudo bíblico',
      note: 'Crescimento na Palavra juntos',
    },
  ] as const,
  /**
   * Horários iniciais — confirmar com a secretaria e ajustar neste arquivo.
   * Fonte de contato oficial IPIB: (14) 3733-3020 / primeiraipiavare@gmail.com
   */
  servicesNote:
    'Horários sujeitos a confirmação pela secretaria. Ligue para validar a programação da semana.',
  ministries: [
    {
      name: 'Louvor',
      description: 'Música e adoração que apontam para Cristo.',
    },
    {
      name: 'Diaconato',
      description: 'Cuidado prático e acolhimento à comunidade.',
    },
    {
      name: 'Crianças e adolescentes',
      description: 'Formação e discipulado das novas gerações.',
    },
    {
      name: 'Intercessão',
      description: 'Oração pela igreja, pela cidade e pelas famílias.',
    },
  ],
} as const;

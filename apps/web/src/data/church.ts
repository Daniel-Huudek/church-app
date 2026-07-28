export const church = {
  brand: 'IPI Avaré',
  logoLabel: 'PRIMEIRA IPI AVARÉ',
  fullName: '1ª Igreja Presbiteriana Independente de Avaré',
  about:
    'A 1ª Igreja IPI de Avaré com o objetivo de levar a todos o amor e a salvação que existem em Jesus Cristo.',
  nav: [
    { label: 'Nossa Igreja', href: '#nossa-igreja' },
    { label: 'O que somos', href: '#o-que-somos' },
    {
      label: 'IPI Comunica',
      href: '#ipi-comunica',
      children: [
        { label: 'Notícias', href: '#noticias' },
        { label: 'Transmissões', href: '#transmissoes' },
        { label: 'Palavra da semana', href: '#palavra' },
      ],
    },
  ] as const,  social: [
    { label: 'Facebook', href: '#', icon: 'facebook' as const },
    { label: 'Instagram', href: '#', icon: 'instagram' as const },
    { label: 'YouTube', href: '#', icon: 'youtube' as const },
  ],
  series: {
    title: 'Adoração e soberania de Deus',
    subtitle: 'Igreja adoradora',
    caption: 'Série de mensagens',
  },
  events: [
    {
      title: 'Projeto Ipi Avaré',
      date: '3 de agosto de 2025',
      time: '12:00',
    },
    {
      title: 'Projeto Ipi Avaré',
      date: '10 de agosto de 2025',
      time: '12:00',
    },
    {
      title: 'Projeto Ipi Avaré',
      date: '17 de agosto de 2025',
      time: '12:00',
    },
    {
      title: 'Projeto Ipi Avaré',
      date: '24 de agosto de 2025',
      time: '12:00',
    },
  ],
  weeklyWord: {
    text: 'Não temas, porque eu sou contigo; não te assombres, porque eu sou o teu Deus; eu te fortaleço, e te ajudo, e te sustento com a destra da minha justiça.',
    reference: 'Isaías 41:10',
  },
  news: [
    { id: 'n1', title: 'Notícia 1' },
    { id: 'n2', title: 'Notícia 2' },
    { id: 'n3', title: 'Notícia 3' },
    { id: 'n4', title: 'Notícia 4' },
  ],
  streams: [
    { id: 's1', title: 'Transmissão 1' },
    { id: 's2', title: 'Transmissão 2' },
    { id: 's3', title: 'Transmissão 3' },
    { id: 's4', title: 'Transmissão 4' },
  ],
  usefulLinks: [
    { label: 'Notícias', href: '#noticias' },
    { label: 'O que nós Cremos', href: '#o-que-somos' },
    { label: 'Eventos', href: '#eventos' },
  ],
  address: {
    line: 'R. Goiás, 1142 — Centro, Avaré — SP, 18700-140',
    email: 'escritorio@ipiavare.com.br',
    emailHref: 'mailto:escritorio@ipiavare.com.br',
    mapUrl:
      'https://www.google.com/maps/search/?api=1&query=Rua+Goi%C3%A1s+1142+Avar%C3%A9+SP',
    mapEmbed:
      'https://maps.google.com/maps?q=Rua%20Goi%C3%A1s%201142%20Avar%C3%A9%20SP&t=&z=16&ie=UTF8&iwloc=&output=embed',
  },
} as const;

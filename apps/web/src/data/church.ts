export const church = {
  brand: 'IPI Avaré',
  logoLabel: 'PRIMEIRA IPI AVARÉ',
  fullName: '1ª Igreja Presbiteriana Independente de Avaré',
  about:
    'A 1ª Igreja IPI de Avaré com o objetivo de levar a todos o amor e a salvação que existem em Jesus Cristo.',
  nav: [
    {
      label: 'Nossa Igreja',
      href: '/',
      children: [
        { label: 'Início', href: '/' },
        { label: 'Nossa Liderança', href: '/lideranca' },
      ],
    },
    {
      label: 'O que cremos',
      href: '/afirmacao-de-fe',
      children: [{ label: 'Afirmação de Fé', href: '/afirmacao-de-fe' }],
    },
    {
      label: 'IPI Comunica',
      href: '/#ipi-comunica',
      children: [
        { label: 'Notícias', href: '/#noticias' },
        { label: 'Transmissões', href: '/#transmissoes' },
        { label: 'Palavra da semana', href: '/#palavra' },
      ],
    },
  ],
  social: [
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
  faith: {
    titlePrefix: 'Afirmação de Fé da',
    titleAccent: 'IPI do Brasil',
    paragraphs: [
      'Cremos na Santa Trindade, modelo de comunhão, unidade e amor.',
      'Cremos no Deus Pai, criador dos céus e da terra e de todos os seres humanos.',
      'Cremos em Jesus Cristo, seu único Filho, nosso Senhor e Salvador, que traz boas notícias aos pobres, liberdade aos cativos, vista aos cegos, libertação aos oprimidos e perdão para os nossos pecados.',
      'Cremos no Espírito Santo derramado sobre filhos e filhas, moços e velhos, servos e servas.',
      'Cremos na Igreja, família da fé, que abriga, acolhe e promove uma espiritualidade fundamentada na graça de Deus, que traz vida em plenitude, segundo as Sagradas Escrituras.',
      'Cremos que nossa missão é a proclamação do Evangelho do Reino de Deus, para paz, justiça, liberdade e solidariedade entre todos, até que Jesus Cristo volte.',
      'Amém.',
    ],
  },
  leadership: {
    titlePrefix: 'Nossa',
    titleAccent: 'Liderança',
    name: 'Nome completo do pastor',
    role: 'Pastor da 1ª Igreja Presbiteriana Independente de Avaré',
    image: '/pastor.png',
    bio: 'Michel F. Piragine atua ministerialmente na Primeira Igreja Batista de Curitiba há mais de 20 anos. É teólogo pela Faculdade Batista do Paraná, autor do livro "Comportamentos Tóxicos", exerce ministério integral, assim como seu pai, o Pr. Paschoal Piragine Jr., amando e servindo as pessoas. Casado com Silvana Dominguez Piragine, é pai de Beni e Nina Piragine. Sua missão é fazer o nome de Jesus conhecido em toda a Terra. É um visionário no Reino de Deus, seguindo Sua Voz e sendo usado por Ele, para impactar essa geração e comunicar o evangelho por todos os meios disponíveis nas plataformas digitais. Foi o idealizador do primeiro culto no estádio Joaquim Américo Guimarães, juntamente a outros pastores do movimento "Semana de Avivamento", realizando o primeiro culto em 2017. Dois anos depois, em 2019, repetiu o feito, batendo o recorde de público do estádio, com mais de 45.000 pessoas levantando o nome de Jesus.',
  },
  usefulLinks: [
    { label: 'Notícias', href: '/#noticias' },
    { label: 'O que nós Cremos', href: '/afirmacao-de-fe' },
    { label: 'Eventos', href: '/#eventos' },
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

export type NavItem = (typeof church.nav)[number];

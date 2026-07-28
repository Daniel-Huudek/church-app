export type SocialIcon = 'facebook' | 'instagram' | 'youtube';

export type NavChild = {
  label: string;
  href: string;
};

export type NavItem = {
  label: string;
  href: string;
  children?: NavChild[];
};

export type MediaItem = {
  id: string;
  title: string;
  image?: string;
};

export type ChurchEvent = {
  title: string;
  date: string;
  time: string;
  image?: string;
};

export type ChurchContent = {
  brand: string;
  logoLabel: string;
  logoUrl?: string;
  fullName: string;
  about: string;
  nav: NavItem[];
  social: Array<{ label: string; href: string; icon: SocialIcon }>;
  series: {
    title: string;
    subtitle: string;
    caption: string;
    image?: string;
  };
  events: ChurchEvent[];
  weeklyWord: {
    text: string;
    reference: string;
  };
  news: MediaItem[];
  streams: MediaItem[];
  faith: {
    titlePrefix: string;
    titleAccent: string;
    paragraphs: string[];
  };
  leadership: {
    titlePrefix: string;
    titleAccent: string;
    name: string;
    role: string;
    image: string;
    bio: string;
  };
  usefulLinks: Array<{ label: string; href: string }>;
  address: {
    line: string;
    email: string;
    emailHref: string;
    mapUrl: string;
    mapEmbed: string;
  };
};

export const defaultChurchContent: ChurchContent = {
  brand: 'IPI Avaré',
  logoLabel: 'PRIMEIRA IPI AVARÉ',
  logoUrl: '/logo.png',
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
    { label: 'Facebook', href: '#', icon: 'facebook' },
    { label: 'Instagram', href: '#', icon: 'instagram' },
    { label: 'YouTube', href: '#', icon: 'youtube' },
  ],
  series: {
    title: 'Adoração e soberania de Deus',
    subtitle: 'Igreja adoradora',
    caption: 'Série de mensagens',
    image: '',
  },
  events: [
    { title: 'Projeto Ipi Avaré', date: '3 de agosto de 2025', time: '12:00', image: '' },
    { title: 'Projeto Ipi Avaré', date: '10 de agosto de 2025', time: '12:00', image: '' },
    { title: 'Projeto Ipi Avaré', date: '17 de agosto de 2025', time: '12:00', image: '' },
    { title: 'Projeto Ipi Avaré', date: '24 de agosto de 2025', time: '12:00', image: '' },
  ],
  weeklyWord: {
    text: 'Não temas, porque eu sou contigo; não te assombres, porque eu sou o teu Deus; eu te fortaleço, e te ajudo, e te sustento com a destra da minha justiça.',
    reference: 'Isaías 41:10',
  },
  news: [
    { id: 'n1', title: 'Notícia 1', image: '' },
    { id: 'n2', title: 'Notícia 2', image: '' },
    { id: 'n3', title: 'Notícia 3', image: '' },
    { id: 'n4', title: 'Notícia 4', image: '' },
  ],
  streams: [
    { id: 's1', title: 'Transmissão 1', image: '' },
    { id: 's2', title: 'Transmissão 2', image: '' },
    { id: 's3', title: 'Transmissão 3', image: '' },
    { id: 's4', title: 'Transmissão 4', image: '' },
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
    bio: 'Atualize a biografia do pastor no app (Painel → Site).',
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
};

/** @deprecated Prefer useChurch() — kept for fallback imports */
export const church = defaultChurchContent;

import type { WebsiteContentPayload } from './schema.js';

export const DEFAULT_WEBSITE_CONTENT: WebsiteContentPayload = {
  brand: 'IPI Avaré',
  logoLabel: 'PRIMEIRA IPI AVARÉ',
  logoUrl: '/logo.png',
  fullName: '1ª Igreja Presbiteriana Independente de Avaré',
  about:
    'A 1ª Igreja IPI de Avaré com o objetivo de levar a todos o amor e a salvação que existem em Jesus Cristo.',
  nav: [
    {
      label: 'Nossa Igreja',
      href: '/nossa-igreja',
      children: [
        { label: 'Nossa Igreja', href: '/nossa-igreja' },
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
  slides: [],
  events: [],
  weeklyWord: {
    text: 'Não temas, porque eu sou contigo; não te assombres, porque eu sou o teu Deus; eu te fortaleço, e te ajudo, e te sustento com a destra da minha justiça.',
    reference: 'Isaías 41:10',
  },
  news: [],
  streams: [],
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
  ourChurch: {
    titlePrefix: 'Nossa',
    titleAccent: 'Igreja',
    history: [
      'A 1ª Igreja Presbiteriana Independente de Avaré nasceu do desejo de anunciar o Evangelho de Jesus Cristo nesta cidade, formando uma comunidade de fé, comunhão e serviço.',
      'Ao longo dos anos, temos buscado viver a Palavra com simplicidade e fidelidade — acolhendo famílias, discipulando gerações e sendo luz no Centro de Avaré.',
      'Somos uma igreja local da IPI do Brasil, guiada pela graça de Deus e comprometida com a missão de proclamar o Reino até que Cristo volte.',
    ],
    image: '',
    schedule: [
      { day: 'Quartas-feiras', time: '20h', label: 'Culto' },
      { day: 'Domingos', time: '19h30', label: 'Culto' },
    ],
  },
  usefulLinks: [
    { label: 'Nossa Igreja', href: '/nossa-igreja' },
    { label: 'Notícias', href: '/#noticias' },
    { label: 'O que nós Cremos', href: '/afirmacao-de-fe' },
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

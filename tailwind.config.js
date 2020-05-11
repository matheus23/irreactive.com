module.exports = {
  purge: [
    './src/*.elm',
    './src/**/*.elm',
  ],
  theme: {
    extend: {
      fontSize: {
        'base': '1.125rem',
        'base-sm': '0.875rem',
      },
      colors: {
        'gruv-red-d': 'rgba(157,0,6,1)',
        'gruv-red-m': 'rgba(204,36,29,1)',
        'gruv-red-l': 'rgba(251,73,52,1)',
        'gruv-green-d': 'rgba(121,116,14,1)',
        'gruv-green-m': 'rgba(152,151,26,1)',
        'gruv-green-l': 'rgba(184,187,38,1)',
        'gruv-yellow-d': 'rgba(181,118,20,1)',
        'gruv-yellow-m': 'rgba(215,153,33,1)',
        'gruv-yellow-l': 'rgba(250,189,47,1)',
        'gruv-blue-d': 'rgba(7,102,120,1)',
        'gruv-blue-m': 'rgba(69,133,136,1)',
        'gruv-blue-l': 'rgba(131,165,152,1)',
        'gruv-purple-d': 'rgba(143,63,113,1)',
        'gruv-purple-m': 'rgba(177,98,134,1)',
        'gruv-purple-l': 'rgba(211,134,155,1)',
        'gruv-aqua-d': 'rgba(66,123,88,1)',
        'gruv-aqua-m': 'rgba(104,157,106,1)',
        'gruv-aqua-l': 'rgba(142,192,124,1)',
        'gruv-orange-d': 'rgba(175,58,3,1)',
        'gruv-orange-m': 'rgba(214,93,14,1)',
        'gruv-orange-l': 'rgba(254,128,25,1)',
        'gruv-gray-0': 'rgba(29,32,33,1)',
        'gruv-gray-1': 'rgba(40,40,40,1)',
        'gruv-gray-1s': 'rgba(50,48,47,1)',
        'gruv-gray-2': 'rgba(60,56,54,1)',
        'gruv-gray-3': 'rgba(80,73,69,1)',
        'gruv-gray-4': 'rgba(102,92,84,1)',
        'gruv-gray-5': 'rgba(124,111,100,1)',
        'gruv-gray-6': 'rgba(146,131,116,1)',
        'gruv-gray-7': 'rgba(168,153,132,1)',
        'gruv-gray-8': 'rgba(189,174,147,1)',
        'gruv-gray-9': 'rgba(213,196,161,1)',
        'gruv-gray-10': 'rgba(235,219,178,1)',
        'gruv-gray-10s': 'rgba(242,229,188,1)',
        'gruv-gray-11': 'rgba(251,241,199,1)',
        'gruv-gray-12': 'rgba(249,245,215,1)',
      }
    },
    fontFamily: {
      'title': ['Zilla Slab'],
      'code': ['Fira Code'],
      'main': ['sans serif'],
    }
  },
  variants: {
    textColor: ['visited', 'focus']
  },
  plugins: [],
}
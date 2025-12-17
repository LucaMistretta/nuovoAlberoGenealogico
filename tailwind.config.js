import defaultTheme from 'tailwindcss/defaultTheme';

/** @type {import('tailwindcss').Config} */
export default {
    darkMode: 'class',
    content: [
        './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
        './storage/framework/views/*.php',
        './resources/**/*.blade.php',
        './resources/**/*.js',
        './resources/**/*.vue',
    ],
    theme: {
        extend: {
            fontFamily: {
                sans: ['Figtree', ...defaultTheme.fontFamily.sans],
            },
            colors: {
                // Tema scuro (default)
                dark: {
                    bg: {
                        primary: '#1a1a1a',
                        secondary: '#2d2d2d',
                        tertiary: '#3a3a3a',
                    },
                    text: {
                        primary: '#ffffff',
                        secondary: '#b0b0b0',
                        tertiary: '#808080',
                    },
                    border: '#404040',
                },
                // Tema chiaro
                light: {
                    bg: {
                        primary: '#ffffff',
                        secondary: '#f5f5f5',
                        tertiary: '#e5e5e5',
                    },
                    text: {
                        primary: '#1a1a1a',
                        secondary: '#4a4a4a',
                        tertiary: '#6a6a6a',
                    },
                    border: '#d0d0d0',
                },
            },
        },
    },
    plugins: [],
};


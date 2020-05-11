module.exports = {
    plugins: [
        require('tailwindcss'),
        // require('autoprefixer'),
        require('@fullhuman/postcss-purgecss')({
            content: [
                './src/**/*.elm'
            ],
            defaultExtractor: content => content.match(/[\w-/:]+(?<!:)/g) || []

        }),
    ]
}

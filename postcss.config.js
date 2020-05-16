module.exports = {
    plugins: [
        require('tailwindcss'),
        require('autoprefixer'),
        // the tailwindcss plugin seems to do purgeing itself.
        // require('@fullhuman/postcss-purgecss')({
        //     content: [
        //         './src/*.elm',
        //         './src/**/*.elm'
        //     ],
        //     defaultExtractor: content => content.match(/[\w-/:]+(?<!:)/g) || []

        // }),
    ]
}
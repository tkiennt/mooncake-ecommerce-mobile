// Product images can be a URL from the API or a bundled asset. A bundled asset is a number on
// native but can be an object on web, so only wrap plain strings.
export const imageSource = (image) => (typeof image === 'string' ? { uri: image } : image);

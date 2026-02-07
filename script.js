
const API_KEY = "0df1db71ebcd4be392e29c497fe1926e"; //Geoapify key

const map = L.map('map').setView([40.44, -79.99], 13);

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
attribution: '© OpenStreetMap contributors'
}).addTo(map);

map.on('click', async ({ latlng }) => {
const { lat, lng } = latlng;

try {
    // Call Place Details API with lat/lon
    const url = `https://api.geoapify.com/v2/place-details?lat=${lat}&lon=${lng}&apiKey=${API_KEY}`;

    const response = await fetch(url);
    const result = await response.json();

    if (!result.features || result.features.length === 0) {
    L.popup()
        .setLatLng([lat, lng])
        .setContent("No place detail found here.")
        .openOn(map);
    return;
    }

    const props = result.features[0].properties;
    const name = props.name || "Unknown place";
    const address = props.formatted || "No address available";
    const categories = props.categories ? props.categories.join(", ") : "Unknown type";
    const phone = props.phone ? props.phone : "";
    const website = props.website
    ? `<br><a href="${props.website}" target="_blank">Website</a>`
    : "";

    const content =
    `<b>${name}</b><br>` +
    `Category: ${categories}<br>` +
    `Address: ${address}` +
    (phone ? `<br>Phone: ${phone}` : "") +
    website;

    L.popup()
    .setLatLng([lat, lng])
    .setContent(content)
    .openOn(map);

} catch (err) {
    console.error(err);
    L.popup()
    .setLatLng([lat, lng])
    .setContent("Error fetching place details.")
    .openOn(map);
}
});


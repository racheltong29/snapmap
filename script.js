
const API_KEY = "0df1db71ebcd4be392e29c497fe1926e"; // Geoapify key
const MAPTILER_KEY = "LIrIBVdY1C3aCgd9pexM"; // MapTiler key

// Use MapTiler vector style so we can recolor layers
const styleUrl = `https://api.maptiler.com/maps/streets/style.json?key=${MAPTILER_KEY}`;

const map = new maplibregl.Map({
    container: 'map',
    style: styleUrl,
    center: [-79.99, 40.44], // [lon, lat]
    zoom: 13
});

map.addControl(new maplibregl.NavigationControl());

map.on('load', () => {
    // Recolor layers: iterate style layers and adjust buildings and roads
    const style = map.getStyle();
    console.log('Map style layers:', style?.layers?.map(l => ({ id: l.id, type: l.type })));
    
    if (style && style.layers) {
        style.layers.forEach((layer) => {
            if (!layer.id) return;
            const id = layer.id.toLowerCase();
            
            try {
                // Match building layers (various naming conventions)
                if ((id.includes('building') || id.includes('bldg') || id.includes('structure')) && 
                    (layer.type === 'fill' || layer.type === 'fill-extrusion')) {
                    console.log('Recoloring building layer:', layer.id);
                    map.setPaintProperty(layer.id, 'fill-color', '#c8f7d4'); // pastel green
                    map.setPaintProperty(layer.id, 'fill-opacity', 0.8);
                    if (layer.type === 'fill-extrusion') {
                        map.setPaintProperty(layer.id, 'fill-extrusion-color', '#c8f7d4');
                    }
                }

                // Match road/street layers
                if ((id.includes('road') || id.includes('street') || id.includes('highway') || 
                     id.includes('motorway') || id.includes('path') || id.includes('way')) && 
                    layer.type === 'line') {
                    console.log('Recoloring road layer:', layer.id);
                    map.setPaintProperty(layer.id, 'line-color', '#bfe9ff'); // pastel blue
                    map.setPaintProperty(layer.id, 'line-width', 2);
                }
            } catch (e) {
                // some layers may not accept paint changes; ignore errors
                console.warn('Could not recolor layer', layer.id, e);
            }
        });
    }
});

map.on('click', async (e) => {
    const { lat, lng } = e.lngLat;
    try {
        const url = `https://api.geoapify.com/v2/place-details?lat=${lat}&lon=${lng}&apiKey=${API_KEY}`;
        const response = await fetch(url);
        const result = await response.json();

        if (!result.features || result.features.length === 0) {
            new maplibregl.Popup().setLngLat([lng, lat]).setHTML('No place detail found here.').addTo(map);
            return;
        }

        const props = result.features[0].properties;
        const name = props.name || 'Unknown place';
        const address = props.formatted || 'No address available';
        const categories = props.categories ? props.categories.join(', ') : 'Unknown type';
        const phone = props.phone ? props.phone : '';
        const website = props.website ? `<br><a href="${props.website}" target="_blank">Website</a>` : '';

        const content = `<b>${name}</b><br>Category: ${categories}<br>Address: ${address}` + (phone ? `<br>Phone: ${phone}` : '') + website;

        new maplibregl.Popup().setLngLat([lng, lat]).setHTML(content).addTo(map);
    } catch (err) {
        console.error(err);
        new maplibregl.Popup().setLngLat([lng, lat]).setHTML('Error fetching place details.').addTo(map);
    }
});


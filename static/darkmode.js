function setMode(mode) {
    if (mode == 'light') {
        // Use the light.css stylesheet
        document.querySelector('link[rel="stylesheet"][href="/light.css"]').media = '';
        document.querySelector('link[rel="stylesheet"][href="/dark.css"]').media = 'none';
        // Set the button with id "darkmodebutton" to say "Dark Mode"
        document.getElementById('darkmodebutton').textContent = 'Dark Mode';
    } else if (mode == 'dark') {
        // Use the dark.css stylesheet
        document.querySelector('link[rel="stylesheet"][href="/light.css"]').media = 'none';
        document.querySelector('link[rel="stylesheet"][href="/dark.css"]').media = '';
        // Set the button with id "darkmodebutton" to say "Light Mode"
        document.getElementById('darkmodebutton').textContent = 'Light Mode';
    }
}

function toggleDarkMode() {
    // First, check if we've set the dark mode cookie
    const darkModeCookie = document.cookie.includes('darkMode=true');

    // Toggle the dark mode based on the cookie value
    if (darkModeCookie) {
        setMode('light');
        document.cookie = 'darkMode=false; path=/';
    } else {
        setMode('dark');
        document.cookie = 'darkMode=true; path=/';
    }
}

if (document.cookie.includes('darkMode=true')) {
    setMode('dark');
}
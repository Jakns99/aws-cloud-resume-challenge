const counter = document.querySelector(".counter");

async function updateCounter() {
    let response = await fetch("https://r9se0ydrv1.execute-api.us-west-2.amazonaws.com/Prod");
    let data = await response.json();
    counter.innerHTML = ` Total Views: ${data}`;
}

updateCounter();

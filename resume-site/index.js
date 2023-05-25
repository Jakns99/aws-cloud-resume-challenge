const counter = document.querySelector(".counter");
async function updateCounter() {
    let response = await fetch("https://ulc5lu5vlnej3hcqucqdqnkujy0mldzk.lambda-url.us-west-2.on.aws/");
    let data = await response.json();
    counter.innerHTML = ` Total Views: ${data}`;
}

updateCounter();
const API = (url, data=null) => {
  return fetch(url, {
    method: data ? "POST" : "GET",
    headers: {"Content-Type":"application/x-www-form-urlencoded"},
    body: data ? new URLSearchParams(data) : null
  }).then(r => r.json());
};

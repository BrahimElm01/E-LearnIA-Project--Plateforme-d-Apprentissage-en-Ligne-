document.getElementById("loginForm").addEventListener("submit", async e => {
  e.preventDefault();
  const email = emailInput.value;
  const password = passwordInput.value;

  const res = await API("backend/auth.php", {email, password});
  if(res.success){
    window.location = res.role === "teacher" ? "teacher-dashboard.html" : "student-dashboard.html";
  }else{
    alert(res.message);
  }
});

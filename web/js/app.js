document.addEventListener('DOMContentLoaded', () => {
  const cards = document.querySelectorAll('.card');
  cards.forEach((card, index) => {
    card.style.animationDelay = `${index * 80}ms`;
    card.style.animation = 'fadeIn 0.5s ease forwards';
  });
});

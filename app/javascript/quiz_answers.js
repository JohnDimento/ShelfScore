document.addEventListener('DOMContentLoaded', function() {
  const form = document.getElementById('quiz-form');
  if (!form) return;

  const radioButtons = form.querySelectorAll('input[type="radio"]');

  radioButtons.forEach(radio => {
    radio.addEventListener('change', function() {
      const questionId = this.dataset.questionId;
      const answer = this.value;

      fetch('/quiz_answers', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          question_id: questionId,
          answer: answer
        })
      }).then(response => {
        if (!response.ok) {
          console.error('Failed to save answer');
        }
      });
    });
  });
}); 
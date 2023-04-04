describe('spec.cy.js', () => {
  it('should visit', () => {
    cy.visit('localhost:4567/')
    cy.contains('Login').click()
    
    cy.contains('Register').click()

    cy.contains('Home').click()

    cy.contains('this is the title of the post').click()

    cy.contains('admin').click()

    cy.contains('Posts').click()

    cy.contains('ahwkdhkwa').click()

    cy.contains('funny').click()
  })
})    
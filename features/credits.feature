Feature: Credits
  Credit is the action of moving money out of the marketplace.
  The money will come from either the marketplace's escrow balance
  or an order and can be sent to a bank account.  If sent to a customer
  then that customer's default bank account will be used instead.

  Scenario: Credit a bank account
    Given I have sufficient funds in my marketplace
    And I have tokenized a bank account
    When I POST to /bank_accounts/:bank_account_id/credits with the body:
      """
      {
        "credits": [{
          "amount": 1234
        }]
      }
      """
    Then I should get a 201 Created status code
    And the response is valid according to the "credits" schema

  Scenario: List credits
    Given I have more than two credits
    When I GET to /credits
    Then I should get a 200 OK status code
    And the response is valid according to the "credits" schema

  Scenario: Retrieving credits for a bank account
    Given I have a bank account with a credit
    When I GET to /bank_accounts/:bank_account_id/credits
    Then I should get a 200 OK status code
    And the response is valid according to the "credits" schema
    And the fields on these credits match:
      """
      {
        "links": {
          "destination": ":bank_account_id"
        }
      }
      """

  Scenario: Updating a credit description
    Given I have a bank account with a credit
    When I PUT to /credits/:credit_id with the body:
      """
      {
        "description": "A new credit description"
      }
      """
    Then I should get a 200 OK status code
    And the response is valid according to the "credits" schema
    And the fields on this credit match:
      """
      {
        "description": "A new credit description"
      }
      """

  Scenario: Updating a credit meta
    Given I have a bank account with a credit
    When I PUT to /credits/:credit_id with the body:
      """
      {
        "meta": {
          "something": "random"
        }
      }
      """
    Then I should get a 200 OK status code
    And the response is valid according to the "credits" schema
    And the fields on this credit match:
      """
      {
        "meta": {
          "something": "random"
        }
      }
      """

  Scenario: Crediting a deleted card leads to failure
    Given I have tokenized a card
    When I make a DELETE request to the href "href"

    When I make a POST request to /cards/:card_id/credits
    Then I should get a 400 status code

    And the response is valid according to the "errors" schema
    And the fields on this error match:
    """
      {
       "category_code": "request"
      }
    """

  Scenario: Credit a customer
    Given I have a customer with a tokenized bank account
    When  I POST to /customers/:customer_id/credits with the body:
    """
      {
        "credits": [{
          "amount": 500,
          "appears_on_statement_as": "Your lucky day"
        }]
      }
    """
    Then I should get a 201 Created status code
    And the response is valid according to the "credits" schema

  Scenario: Crediting without a funding source leads to failure
    Given I have created a customer
    When I POST to /customers/:customer_id/credits with the body:
    """
      {
        "credits": [{
          "amount": 1234,
          "description": "Will this credit work? Nobody knows"
        }]
      }
    """
    Then I should get a 409 status code
    And the response is valid according to the "errors" schema
    And the fields on this error match:
    """
      {
       "category_code": "no-funding-destination"
      }
    """


  Scenario: Bulk credit to a customer payable account
    Given I have a merchant with 2 orders with debits
    When I POST to /accounts/:customer_payable_account_id/credits with the body:
    """
      {
        "credits": [{
          "amount": 1000,
          "order": "/orders/:order_id_1",
          "appears_on_statement_as": "Payout group A"
        }]
      }
    """
    Then I should get a 201 Created status code
    And the response is valid according to the "credits" schema

    When I make a GET request to /accounts/:customer_payable_account_id
    Then I should get a 200 OK status code
    And the fields on this account match:
    """
      {
       "balance": 1000
      }
    """

    When I POST to /accounts/:customer_payable_account_id/credits with the body:
    """
      {
        "credits": [{
          "amount": 1000,
          "order": "/orders/:order_id_2",
          "appears_on_statement_as": "Payout group B"
        }]
      }
    """
    Then I should get a 201 Created status code
    And the response is valid according to the "credits" schema

    When I make a GET request to /accounts/:customer_payable_account_id
    Then I should get a 200 OK status code
    And the fields on this account match:
    """
      {
       "balance": 2000
      }
    """

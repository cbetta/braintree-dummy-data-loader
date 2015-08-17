require "braintree"
require "faker"

Braintree::Configuration.environment = :sandbox
Braintree::Configuration.merchant_id = ""
Braintree::Configuration.public_key = ""
Braintree::Configuration.private_key = ""

@cards = ['4111111111111111' , '5555555555554444', '378282246310005' , '6011111111111117' , '3530111333300000']


def get_customer
  find_customer || create_customer
end

def find_customer
  return nil if rand < 0.2
  search_results = Braintree::Customer.search do |search|
    search.created_at >= Time.now - 60*60*24*(0..100).to_a.sample
  end.to_a.shuffle.first
end

def create_customer
  customer = Braintree::Customer.create({
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.email,
      phone: Faker::PhoneNumber.phone_number,
  }).customer
end

customer_count = (1..10).to_a.sample
puts "Using #{customer_count} customers"

customer_count.times do
  @customer = get_customer

  if @customer.credit_cards.count == 0
    card_count = (1..2).to_a.sample
    puts "Adding #{card_count} cards"
    card_count.times do
      number = @cards.sample
      Braintree::CreditCard.create(
        :customer_id => @customer.id,
        :number => number,
        :expiration_month => "11",
        :expiration_year => "21",
        :cvv => number.length == 16 ? "123" : "1234"
      )
    end

    @customer = Braintree::Customer.find(@customer.id)
  end

  transaction_count = (1..5).to_a.sample
  puts "Creating #{transaction_count} transactions"

  transaction_count.times do
    amount = "#{Faker::Number.number((1..3).to_a.sample)}.#{Faker::Number.number(2)}"

    result = Braintree::Transaction.sale(
      :amount => amount,
      customer_id: @customer.id,
      payment_method_token:  @customer.credit_cards.sample.token
    )
  end
end

package BookingService;

use Moose;

use Account; 
use MarketClient;
use Trade;
use TradingArgs;

has market => ( is => 'ro', isa => 'MarketClient' );
has firmAccount => ( is => 'ro', isa => 'Account' );

has customerAccount => ( is => 'ro', isa => 'Account' );
has trade => ( is => 'ro', isa => 'Trade' );
has commission => ( is => 'ro', isa => 'Math::BigFloat' );

sub fromArgs {
    my( $class, @args ) = @_;
    my $args = TradingArgs->new( args => \@args );
    $class->new(
        market => MarketClient->getInstance(),
        firmAccount => Account->getFirmAccount(),
        customerAccount => Account->getCustomerAccount( $args->getAccountKey ),
        trade => Trade->new(
            symbol => $args->getSymbol(),
            quantity => $args->getQuantity()
        ),
        commission => $args->getCommission(),
    )
}

sub buy {
    my $self = shift;
    my $price = $self->market->getPrice($self->trade->symbol);
    my $marketValue = $price->bmul( $self->trade->quantity );
    my $settlementAmount = $marketValue->badd( $self->commission );
    my $firmAccount = $self->firmAccount;
    $self->customerAccount->transferCash( $settlementAmount, $firmAccount );
    $firmAccount->transferSecurity( $self->trade->symbol, $self->trade->quantity, $self->customerAccount);
}

1;

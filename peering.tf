resource "aws_vpc_peering_connection" "owner" {
  peer_owner_id = "863518411655"
  peer_vpc_id = aws_vpc.vpc2.id
  vpc_id = aws_vpc.vpc1.id
  peer_region = "us-east-2"
  auto_accept = false
  tags = {
    Name = "dev-prod"
  }
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
  provider = aws.central
  vpc_peering_connection_id = aws_vpc_peering_connection.owner.id
  auto_accept = true
  tags = {
    Name = "prod-dev"
  }
}
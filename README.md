# ERC721 ERC20 Swap Protocol
Exchanging any ERC-721 Token with any chosen ERC-20 Token

## Installation
```bash
git clone https://github.com/seojunchian/ERC721_ERC20_Swap_Protocol
```

## Using Guides
### Official Sepolia Address -> 

### If you're ERC721 Owner -> 
First - Send your token to contract.
Second - Create pair.

### If you're ERC20 Owner ->
First - Check how much ERC20 Token you need.
Second - Approve contract to exchange on your behalf.
Third - Do the swap

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## v2 Ideas of my own
If we are ERC721 owner and want ERC20 in exchange, prices of ERC20 tokens will change by time. It's not just for price being static in here. It should be able to update itself when it comes to swapping. So idea is getting price of erc20 token against a stable coin and deciding is ERC721 owner will get more or less token when it comes to swap. If price of erc20 token goes high ERC721 owner will get less token and if it goes lower ERC721 owner will get more token.

###### 


## License

[MIT](https://choosealicense.com/licenses/mit/)

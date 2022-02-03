------------------------------------------------------------------------------
-- Aergo Standard Token Interface (Proposal) - 20211028
-- Allowed approval
------------------------------------------------------------------------------

state.var {
  -- limited approval
  _allowance = state.map(),   -- address/address -> unsigned_bignum
}


-- Approve an account to spend the specified amount of Tx sender's tokens
-- @type    call
-- @param   spender (address) spender's address
-- @param   amount  (ubig)    amount of allowed tokens
-- @event   approve(Tx sender, spender, amount)

function approve(spender, amount)
  _typecheck(spender, 'address')
  amount = _check_bignum(amount)

  assert(system.getSender() ~= spender, "cannot set approve self")

  _allowance[system.getSender() .. "/" .. spender] = amount

  contract.event("approve", system.getSender(), spender, bignum.tostring(amount))
end


-- Increase the amount of tokens that Tx sender allowed to an account
-- @type    call
-- @param   spender (address) spender's address
-- @param   amount  (ubig)    amount of increased tokens
-- @event   increaseAllowance(Tx sender, spender, amount)

function increaseAllowance(spender, amount)
  _typecheck(spender, 'address')
  amount = _check_bignum(amount)

  local pair = system.getSender() .. "/" .. spender

  assert(_allowance[pair], "not approved")

  _allowance[pair] = _allowance[pair] + amount

  contract.event("increaseAllowance", system.getSender(), spender, bignum.tostring(amount))
end


-- Decrease the amount of tokens that Tx sender allowed to an account
-- @type    call
-- @param   spender (address) spender's address
-- @param   amount  (ubig)    amount of decreased tokens
-- @event   decreaseAllowance(Tx sender, spender, amount)

function decreaseAllowance(spender, amount)
  _typecheck(spender, 'address')
  amount = _check_bignum(amount)

  local pair = system.getSender() .. "/" .. spender

  assert(_allowance[pair], "not approved")

  if _allowance[pair] < amount then
    _allowance[pair] = 0
  else
    _allowance[pair] = _allowance[pair] - amount
  end

  contract.event("decreaseAllowance", system.getSender(), spender, bignum.tostring(amount))
end


-- Get amount of remaining tokens that an account allowed to another
-- @type    query
-- @param   owner   (address) owner's address
-- @param   spender (address) spender's address
-- @return  (number) amount of remaining tokens

function allowance(owner, spender)
  _typecheck(owner, 'address')
  _typecheck(spender, 'address')

  return _allowance[owner .."/".. spender] or bignum.number(0)
end


-- Transfer tokens from an account to another using the allowance mechanism
-- @type    call
-- @param   from   (address) sender's address
-- @param   to     (address) recipient's address
-- @param   amount (ubig)    amount of tokens to send
-- @param   ...     addtional data, MUST be sent unaltered in call to 'tokensReceived' on 'to'
-- @return  _transfer(Tx sender, to, amount, ...)
-- @event   transfer(TX Sender, from, to, amount)

function transferFromLtd(from, to, amount, ...)
  _typecheck(from, 'address')
  _typecheck(to, 'address')
  amount = _check_bignum(amount)

  local pair = from .. "/" .. system.getSender()

  assert(_allowance[pair], "not approved")
  assert(_allowance[pair] >= amount, "insufficient allowance")

  re = _transfer(from, to, amount, ...)
  _allowance[pair] = _allowance[pair] - amount

  contract.event("transfer", system.getSender(), from, to, bignum.tostring(amount))

  return re
end


-- Burn tokens from an account using the allowance mechanism
-- @type    call
-- @param   from    (address) sender's address
-- @param   amount  (ubig)    amount of tokens to burn
-- @event   burn(TX Sender, from, amount)

function burnFromLtd(from, amount)
  _typecheck(from, 'address')
  amount = _check_bignum(amount)

  local pair = from .. "/" .. system.getSender()

  assert(_allowance[pair], "not approved")
  assert(_allowance[pair] >= amount, "insufficient allowance")

  _burn(from, amount)
  _allowance[pair] = _allowance[pair] - amount

  contract.event("burn", system.getSender(), from, bignum.tostring(amount))
end


abi.register(approve,increaseAllowance,decreaseAllowance,transferFromLtd,burnFromLtd)
abi.register_view(allowance)

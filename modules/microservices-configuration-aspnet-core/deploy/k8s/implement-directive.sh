pushd ~/clouddrive/aspnet-learn/src/src/Web/WebSPA/Client/src/modules/orders > /dev/null
sed -i 's/id="subtotalDiv"/*featureFlag="'\''coupons'\''"/' orders-detail/orders-detail.component.html
sed -i 's/id="discountCodeDiv"/*featureFlag="'\''coupons'\''"/' orders-detail/orders-detail.component.html
sed -i 's/id="subtotalDiv"/*featureFlag="'\''coupons'\''"/' orders-new/orders-new.component.html
sed -i 's/id="discountCodeDiv"/*featureFlag="'\''coupons'\''"/' orders-new/orders-new.component.html
popd > /dev/null
echo
echo "Done modifying orders-detail.component.html and orders-new.component.html!"
echo

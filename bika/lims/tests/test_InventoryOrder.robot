*** Settings ***

Library         BuiltIn
Library         Selenium2Library  timeout=5  implicit_wait=0.2
Library         String
Resource        keywords.txt
Resource        plone/app/robotframework/keywords.robot
Library         bika.lims.testing.Keywords
Resource        plone/app/robotframework/selenium.robot
Library         Remote  ${PLONEURL}/RobotRemote
Variables       plone/app/testing/interfaces.py
Variables       bika/lims/tests/variables.py

Suite Setup     Start browser
Suite Teardown  Close All Browsers

Library          DebugLibrary

*** Test Cases ***

Test order as LabManager
    Enable autologin as  LabManager
    # https://jira.bikalabs.com/browse/LIMS-1900
    Given a blank order form in supplier-3
     # Only products registered to a supplier can be ordered to him
     page should not contain  Ink cartridge black PGI-7BK
     When I enter 2 for product Nitric acid
      and I submit the new order
    subtotal is 24.22
    vat is 0.00
    total is 24.22
    Then when I trigger dispatch transition
    page should contain  Item state changed
    Then when I trigger receive transition
    page should contain  Item state changed
    Then when I trigger store transition
    page should contain  Item state changed

Test product reception workflow
    Enable autologin as  LabManager
    Given a blank order form in supplier-3
     When I enter 7 for product Nitric acid
      and I enter 5 for product Sulfuric acid
      and I submit the new order
      and I trigger dispatch transition
      and I trigger receive transition
     Then product items list has Nitric acid
      and product items list has Sulfuric acid
      and quantity of Sulfuric acid in Chemical category is 5


*** Keywords ***

# --- Given ------------------------------------------------------------------

a blank order form in ${supplier_id}
    [Documentation]  Load a fresh Order form
    go to  ${PLONEURL}/bika_setup/bika_suppliers/${supplier_id}/portal_factory/Order/xxx/edit
    wait until page contains  xxx

# --- When -------------------------------------------------------------------

I enter ${nr} for product ${product_title}
    [Documentation]  Simply input the value for this product
    input text   xpath=.//input[@data-product_title='${product_title}']   ${nr}
    press key    xpath=.//input[@data-product_title='${product_title}']   \t

I submit the new order
    [Documentation]  Save the order and wait for the submission to complete
    click button  Save
    wait until page contains  Order pending

I trigger ${transitionId} transition
    Element Should Be Visible  css=dl#plone-contentmenu-workflow span
    Element Should Not Be Visible  css=dl#plone-contentmenu-workflow dd.actionMenuContent
    Click link  css=dl#plone-contentmenu-workflow dt.actionMenuHeader a
    Wait until keyword succeeds  1  5  Element Should Be Visible  css=dl#plone-contentmenu-workflow dd.actionMenuContent
    Click Link  workflow-transition-${transitionId}

# --- Then -------------------------------------------------------------------

status message should be ${message}
    wait until page contains element  css=dl.portalMessage dt  Info
    wait until page contains element  css=dl.portalMessage dd  ${message}

subtotal is ${nr}
    [Documentation]  Verify the subtotal is calculated correctly
    element text should be  css=span.subtotal  ${nr}

vat is ${nr}
    [Documentation]  Verify the vat is calculated correctly
    element text should be  css=span.vat  ${nr}

total is ${nr}
    [Documentation]  Verify the total is calculated correctly
    element text should be  css=span.total  ${nr}

product items list has ${product}
    go to  ${PLONEURL}/bika_setup/bika_suppliers/bika_productitems
    page should contain  ${product}

quantity of ${product} in ${category} category is ${quantity}
    go to  ${PLONEURL}/bika_setup/bika_suppliers/supplier-3/products
    click element  xpath=//th[contains(@cat, '${category}')]
    click link  ${product}
    page should contain element  xpath=//input[@id='Quantity' and @value='${quantity}']
